package rpc

import (
	"google.golang.org/protobuf/types/known/structpb"
)

func MapToStruct(input map[string]any) (*structpb.Struct, error) {
	if input == nil {
		input = map[string]any{}
	}
	return structpb.NewStruct(input)
}

func StructToMap(input *structpb.Struct) map[string]any {
	if input == nil {
		return map[string]any{}
	}
	return input.AsMap()
}
