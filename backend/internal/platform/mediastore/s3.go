package mediastore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"path"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/credentials/stscreds"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/aws/smithy-go"
	smithyhttp "github.com/aws/smithy-go/transport/http"

	"github.com/verified-dating/backend/internal/platform/config"
)

// S3API is the subset of the S3 client the store uses (fakeable in tests).
type S3API interface {
	PutObject(ctx context.Context, in *s3.PutObjectInput, optFns ...func(*s3.Options)) (*s3.PutObjectOutput, error)
	GetObject(ctx context.Context, in *s3.GetObjectInput, optFns ...func(*s3.Options)) (*s3.GetObjectOutput, error)
	HeadObject(ctx context.Context, in *s3.HeadObjectInput, optFns ...func(*s3.Options)) (*s3.HeadObjectOutput, error)
	DeleteObject(ctx context.Context, in *s3.DeleteObjectInput, optFns ...func(*s3.Options)) (*s3.DeleteObjectOutput, error)
}

// S3Presigner presigns GET requests.
type S3Presigner interface {
	PresignGetObject(ctx context.Context, in *s3.GetObjectInput, optFns ...func(*s3.PresignOptions)) (*v4.PresignedHTTPRequest, error)
}

// S3Store keeps media in AWS S3 (or an S3-compatible service).
type S3Store struct {
	api         S3API
	presigner   S3Presigner
	cfg         config.S3StorageConfig
	credentials aws.CredentialsProvider
}

// NewS3 builds an S3 store from configuration (credentials per auth mode).
func NewS3(ctx context.Context, cfg config.S3StorageConfig) (*S3Store, error) {
	client, awsCfg, err := NewS3Client(ctx, cfg)
	if err != nil {
		return nil, err
	}
	store := NewS3WithClient(client, s3.NewPresignClient(client), cfg)
	store.credentials = awsCfg.Credentials
	return store, nil
}

// NewS3WithClient builds an S3 store around an existing client.
func NewS3WithClient(api S3API, presigner S3Presigner, cfg config.S3StorageConfig) *S3Store {
	if cfg.PresignTTL <= 0 {
		cfg.PresignTTL = 5 * time.Minute
	}
	return &S3Store{api: api, presigner: presigner, cfg: cfg}
}

// NewS3Client returns an S3 client configured for the selected auth mode:
//
//   - static:        AWS_S3_ACCESS_KEY_ID / AWS_S3_SECRET_ACCESS_KEY (+ AWS_S3_SESSION_TOKEN)
//   - profile:       AWS_S3_PROFILE from AWS_S3_SHARED_CREDENTIALS_FILE / AWS_S3_SHARED_CONFIG_FILE
//   - default_chain: SDK default chain (env, shared files, EC2 instance role via IMDS, ECS, web identity)
//   - assume_role:   STS AssumeRole into AWS_S3_ROLE_ARN (+ external id), source
//     credentials from static keys, a profile, or the default chain
func NewS3Client(ctx context.Context, cfg config.S3StorageConfig) (*s3.Client, aws.Config, error) {
	region := strings.TrimSpace(cfg.Region)
	if region == "" {
		region = "us-east-1"
	}
	auth := cfg.Auth
	options := []func(*awsconfig.LoadOptions) error{awsconfig.WithRegion(region)}
	staticKeys := func() {
		options = append(options, awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(auth.AccessKeyID, auth.SecretAccessKey, auth.SessionToken)))
	}
	profile := func() {
		options = append(options, awsconfig.WithSharedConfigProfile(auth.Profile))
		if auth.SharedCredentialsFile != "" {
			options = append(options, awsconfig.WithSharedCredentialsFiles([]string{auth.SharedCredentialsFile}))
		}
		if auth.SharedConfigFile != "" {
			options = append(options, awsconfig.WithSharedConfigFiles([]string{auth.SharedConfigFile}))
		}
	}
	switch auth.Mode {
	case config.S3AuthStatic:
		staticKeys()
	case config.S3AuthProfile:
		profile()
	case config.S3AuthDefaultChain, "":
	case config.S3AuthAssumeRole:
		switch {
		case auth.AccessKeyID != "":
			staticKeys()
		case auth.Profile != "":
			profile()
		}
	default:
		return nil, aws.Config{}, fmt.Errorf("mediastore: unsupported AWS_S3_AUTH_MODE %q", auth.Mode)
	}
	awsCfg, err := awsconfig.LoadDefaultConfig(ctx, options...)
	if err != nil {
		return nil, aws.Config{}, fmt.Errorf("mediastore: load AWS configuration (%s): %w", auth.String(), err)
	}
	if auth.Mode == config.S3AuthAssumeRole {
		stsClient := sts.NewFromConfig(awsCfg)
		provider := stscreds.NewAssumeRoleProvider(stsClient, auth.RoleARN, func(o *stscreds.AssumeRoleOptions) {
			o.RoleSessionName = auth.SessionName
			if auth.ExternalID != "" {
				o.ExternalID = aws.String(auth.ExternalID)
			}
			if auth.RoleDuration > 0 {
				o.Duration = auth.RoleDuration
			}
		})
		awsCfg.Credentials = aws.NewCredentialsCache(provider)
	}
	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.UsePathStyle = cfg.ForcePathStyle
		if cfg.Endpoint != "" {
			o.BaseEndpoint = aws.String(cfg.Endpoint)
		}
		// We send our own SHA-256 checksum; automatic CRC trailers break some
		// S3-compatible services.
		o.RequestChecksumCalculation = aws.RequestChecksumCalculationWhenRequired
		o.ResponseChecksumValidation = aws.ResponseChecksumValidationWhenRequired
	})
	return client, awsCfg, nil
}

// VerifyCredentials resolves credentials once so a broken auth setup fails at
// startup instead of on the first upload. It never logs secret values.
func (s *S3Store) VerifyCredentials(ctx context.Context) error {
	if s.credentials == nil {
		return nil
	}
	creds, err := s.credentials.Retrieve(ctx)
	if err != nil {
		return fmt.Errorf("mediastore: resolve AWS credentials (%s): %w", s.cfg.Auth.String(), err)
	}
	if creds.AccessKeyID == "" {
		return fmt.Errorf("mediastore: AWS credentials (%s) resolved to an empty access key", s.cfg.Auth.String())
	}
	return nil
}

// Backend implements Store.
func (s *S3Store) Backend() string { return config.StorageBackendAWSS3 }

// Location maps a logical key to its bucket and object key.
func (s *S3Store) Location(key string) (bucket, objectKey string, spec KindSpec, err error) {
	cleaned, err := CleanKey(key)
	if err != nil {
		return "", "", KindSpec{}, err
	}
	if legacy := s.cfg.LegacyPrefix; legacy != "" && strings.HasPrefix(cleaned, legacy+"/") {
		// Keys written by earlier releases already include the bucket prefix.
		spec, _, classifyErr := Classify(strings.TrimPrefix(cleaned, legacy+"/"))
		if classifyErr != nil {
			spec = SpecFor(KindLegacyProfilePhoto)
		}
		return s.cfg.Bucket, cleaned, spec, nil
	}
	spec, rest, err := Classify(cleaned)
	if err != nil {
		return "", "", KindSpec{}, err
	}
	prefix := s3Prefix(spec.Kind, s.cfg.Prefixes)
	parts := []string{}
	if s.cfg.KeyPrefix != "" {
		parts = append(parts, s.cfg.KeyPrefix)
	}
	parts = append(parts, prefix, rest)
	bucket = s.cfg.Bucket
	if spec.Visibility == VisibilityPublic && s.cfg.PublicBucket != "" {
		bucket = s.cfg.PublicBucket
	}
	return bucket, path.Join(parts...), spec, nil
}

// Put implements Store.
func (s *S3Store) Put(ctx context.Context, key string, body []byte, opts PutOptions) error {
	bucket, objectKey, spec, err := s.Location(key)
	if err != nil {
		return err
	}
	digest := sha256.Sum256(body)
	input := &s3.PutObjectInput{
		Bucket:        aws.String(bucket),
		Key:           aws.String(objectKey),
		Body:          bytes.NewReader(body),
		ContentLength: aws.Int64(int64(len(body))),
		CacheControl:  aws.String(ObjectCacheControl(spec.Visibility)),
		Metadata:      map[string]string{"sha256": hex.EncodeToString(digest[:]), "kind": string(spec.Kind)},
	}
	if opts.ContentType != "" {
		input.ContentType = aws.String(opts.ContentType)
	}
	if s.cfg.SendChecksums {
		input.ChecksumSHA256 = aws.String(base64.StdEncoding.EncodeToString(digest[:]))
	}
	switch s.cfg.SSE {
	case "AES256":
		input.ServerSideEncryption = types.ServerSideEncryptionAes256
	case "aws:kms":
		input.ServerSideEncryption = types.ServerSideEncryptionAwsKms
		if s.cfg.SSEKMSKeyID != "" {
			input.SSEKMSKeyId = aws.String(s.cfg.SSEKMSKeyID)
		}
		if s.cfg.BucketKeyEnabled {
			input.BucketKeyEnabled = aws.Bool(true)
		}
	}
	if _, err := s.api.PutObject(ctx, input); err != nil {
		return fmt.Errorf("mediastore: upload %s to s3://%s: %w", spec.Kind, bucket, err)
	}
	return nil
}

// Open implements Store.
func (s *S3Store) Open(ctx context.Context, key string) (Object, error) {
	bucket, objectKey, _, err := s.Location(key)
	if err != nil {
		return Object{}, err
	}
	output, err := s.api.GetObject(ctx, &s3.GetObjectInput{Bucket: aws.String(bucket), Key: aws.String(objectKey)})
	if err != nil {
		if isS3NotFound(err) {
			return Object{}, ErrNotFound
		}
		return Object{}, fmt.Errorf("mediastore: read s3://%s: %w", bucket, err)
	}
	object := Object{Body: output.Body, Size: aws.ToInt64(output.ContentLength), ContentType: aws.ToString(output.ContentType), SHA256: output.Metadata["sha256"]}
	if output.LastModified != nil {
		object.ModTime = *output.LastModified
	}
	return object, nil
}

// Stat implements Store.
func (s *S3Store) Stat(ctx context.Context, key string) (ObjectInfo, error) {
	bucket, objectKey, _, err := s.Location(key)
	if err != nil {
		return ObjectInfo{}, err
	}
	input := &s3.HeadObjectInput{Bucket: aws.String(bucket), Key: aws.String(objectKey)}
	if s.cfg.SendChecksums {
		input.ChecksumMode = types.ChecksumModeEnabled
	}
	output, err := s.api.HeadObject(ctx, input)
	if err != nil {
		if isS3NotFound(err) {
			return ObjectInfo{}, ErrNotFound
		}
		return ObjectInfo{}, fmt.Errorf("mediastore: stat s3://%s: %w", bucket, err)
	}
	cleaned, _ := CleanKey(key)
	info := ObjectInfo{Key: cleaned, Size: aws.ToInt64(output.ContentLength), SHA256: output.Metadata["sha256"]}
	if checksum := aws.ToString(output.ChecksumSHA256); checksum != "" && !strings.Contains(checksum, "-") {
		if raw, err := base64.StdEncoding.DecodeString(checksum); err == nil && len(raw) == sha256.Size {
			info.SHA256 = hex.EncodeToString(raw)
		}
	}
	if output.LastModified != nil {
		info.ModTime = *output.LastModified
	}
	return info, nil
}

// Exists implements Store.
func (s *S3Store) Exists(ctx context.Context, key string) (bool, error) {
	_, err := s.Stat(ctx, key)
	if errors.Is(err, ErrNotFound) {
		return false, nil
	}
	return err == nil, err
}

// Delete implements Store.
func (s *S3Store) Delete(ctx context.Context, key string) error {
	bucket, objectKey, _, err := s.Location(key)
	if err != nil {
		return err
	}
	if _, err := s.api.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: aws.String(bucket), Key: aws.String(objectKey)}); err != nil && !isS3NotFound(err) {
		return fmt.Errorf("mediastore: delete from s3://%s: %w", bucket, err)
	}
	return nil
}

// Presign implements Store.
func (s *S3Store) Presign(ctx context.Context, key string, ttl time.Duration) (string, error) {
	if s.presigner == nil {
		return "", ErrPresignUnsupported
	}
	bucket, objectKey, _, err := s.Location(key)
	if err != nil {
		return "", err
	}
	if ttl <= 0 {
		ttl = s.cfg.PresignTTL
	}
	request, err := s.presigner.PresignGetObject(ctx, &s3.GetObjectInput{Bucket: aws.String(bucket), Key: aws.String(objectKey)}, s3.WithPresignExpires(ttl))
	if err != nil {
		return "", fmt.Errorf("mediastore: presign s3://%s: %w", bucket, err)
	}
	return request.URL, nil
}

// PublicURL returns the CDN URL (AWS_S3_PUBLIC_BASE_URL) of a public object.
func (s *S3Store) PublicURL(key string) (string, bool) {
	if s.cfg.PublicBaseURL == "" {
		return "", false
	}
	_, objectKey, spec, err := s.Location(key)
	if err != nil || spec.Visibility != VisibilityPublic {
		return "", false
	}
	segments := strings.Split(objectKey, "/")
	for i, segment := range segments {
		segments[i] = url.PathEscape(segment)
	}
	return s.cfg.PublicBaseURL + "/" + strings.Join(segments, "/"), true
}

// ServeMode returns "proxy" or "redirect".
func (s *S3Store) ServeMode() string { return s.cfg.ServeMode }

// PresignTTL returns the configured presign lifetime.
func (s *S3Store) PresignTTL() time.Duration { return s.cfg.PresignTTL }

// Walk implements Store. Listing a bucket is not needed by the application
// (bucket lifecycle rules handle orphans), so it is not supported.
func (s *S3Store) Walk(context.Context, func(ObjectInfo) error) error {
	return errors.New("mediastore: walking an S3 bucket is not supported")
}

func isS3NotFound(err error) bool {
	var noSuchKey *types.NoSuchKey
	var notFound *types.NotFound
	if errors.As(err, &noSuchKey) || errors.As(err, &notFound) {
		return true
	}
	var apiErr smithy.APIError
	if errors.As(err, &apiErr) {
		switch apiErr.ErrorCode() {
		case "NoSuchKey", "NotFound", "404":
			return true
		}
	}
	var responseErr *smithyhttp.ResponseError
	if errors.As(err, &responseErr) && responseErr.HTTPStatusCode() == http.StatusNotFound {
		return true
	}
	return false
}
