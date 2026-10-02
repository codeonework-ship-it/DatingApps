from __future__ import annotations

import base64
import re
import time
from typing import Iterable

from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException, TimeoutException
from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.remote.webelement import WebElement
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


class DatingApp:
    def __init__(self, driver: WebDriver, config):
        self.driver = driver
        self.config = config

    def wait(self, timeout: int | None = None) -> WebDriverWait:
        return WebDriverWait(self.driver, timeout or self.config.default_timeout)

    def ui_text(self, text: str) -> tuple[str, str]:
        return (
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().text("{self._escape(text)}")',
        )

    def ui_text_contains(self, text: str) -> tuple[str, str]:
        return (
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().textContains("{self._escape(text)}")',
        )

    def ui_desc(self, text: str) -> tuple[str, str]:
        return (
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().description("{self._escape(text)}")',
        )

    def ui_desc_contains(self, text: str) -> tuple[str, str]:
        return (
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiSelector().descriptionContains("{self._escape(text)}")',
        )

    def ui_class(self, class_name: str) -> tuple[str, str]:
        return (AppiumBy.CLASS_NAME, class_name)

    def accessibility_id(self, value: str) -> tuple[str, str]:
        return (AppiumBy.ACCESSIBILITY_ID, value)

    def resource_id(self, value: str) -> tuple[str, str]:
        return (AppiumBy.ID, value)

    def qa_locators(self, value: str) -> list[tuple[str, str]]:
        return [
            self.accessibility_id(value),
            self.ui_desc(value),
            self.ui_desc_contains(value),
            self.resource_id(value),
            (AppiumBy.XPATH, f'//*[@hint="{self._escape(value)}"]'),
            # A labelled text field reports its hint as "<label>\n<hint>".
            (AppiumBy.XPATH, f'//android.widget.EditText[starts-with(@hint, "{self._escape(value)}")]'),
        ]

    def wait_for_qa(self, value: str, timeout: int | None = None) -> WebElement:
        return self._wait_for_first_present(self.qa_locators(value), timeout=timeout)

    def tap_qa(self, value: str, timeout: int | None = None) -> WebElement:
        element = self._wait_for_first_clickable(self.qa_locators(value), timeout=timeout)
        self._tap_element_center(element)
        return element

    def tap_qa_coordinate(self, value: str, timeout: int | None = None) -> WebElement:
        element = self._wait_for_first_clickable(self.qa_locators(value), timeout=timeout)
        self._shell_tap_element_center(element)
        return element

    def maybe_tap_qa(self, value: str, timeout: int = 2) -> bool:
        try:
            self.tap_qa(value, timeout=timeout)
            return True
        except TimeoutException:
            return False

    def type_into_qa(self, value: str, text: str, timeout: int | None = None) -> None:
        # Dismiss the IME before resolving the next field: Flutter removes
        # fields below the keyboard from its accessibility tree.
        self.hide_keyboard()
        try:
            field = self._wait_for_first_present(self.qa_locators(value), timeout=timeout)
        except TimeoutException:
            field = self._edit_text_with_hint(value)
        field = self._nested_edit_text(field) or field
        field.click()
        self._clear_if_populated(field)
        is_password = self._is_password_field(field)
        if text and is_password:
            entered = self._shell_type_focused(text) if text.isalnum() else False
            if (
                not entered
                and not self._replace_element_value(field, text)
                and not self._paste_focused_text(text)
            ):
                field.send_keys(text)
        elif text and not is_password and not self._type_focused_text(text):
            field.send_keys(text)
        time.sleep(0.4)
        if text and not is_password and not self._element_or_child_contains(field, text):
            raise TimeoutException(f"Text was not entered into {value}")

    def wait_for_accessibility_id(self, value: str, timeout: int | None = None) -> WebElement:
        return self._wait_for_first_present([self.accessibility_id(value)], timeout=timeout)

    def tap_accessibility_id(self, value: str, timeout: int | None = None) -> WebElement:
        element = self._wait_for_first_clickable([self.accessibility_id(value)], timeout=timeout)
        self._tap_element_center(element)
        return element

    def wait_for_text(self, text: str, timeout: int | None = None) -> WebElement:
        return self._wait_for_first_present(
            [
                self.accessibility_id(text),
                self.ui_text(text),
                self.ui_desc(text),
                self.ui_text_contains(text),
                self.ui_desc_contains(text),
            ],
            timeout=timeout,
        )

    def wait_for_text_contains(self, text: str, timeout: int | None = None) -> WebElement:
        return self._wait_for_first_present(
            [self.ui_text_contains(text), self.ui_desc_contains(text)], timeout=timeout
        )

    def is_text_visible(self, text: str, timeout: int = 3) -> bool:
        try:
            self.wait_for_text(text, timeout=timeout)
            return True
        except TimeoutException:
            return False

    def scroll_sheet_to_text(
        self,
        text: str,
        max_swipes: int = 10,
        timeout: int = 2,
    ) -> bool:
        """Scroll a modal bottom sheet until `text` is on screen.

        A generic bidirectional scroll can move *backwards* to reach the
        start of a list. Inside a
        `DraggableScrollableSheet` that backward drag is a downward swipe on
        the sheet itself, so the sheet is dragged shut: the target is never
        found and the surface under test disappears. Every control below the
        fold — Distance, Smoking, Drinking, Apply — was unreachable that way.

        Swiping forward only keeps the sheet open, so this walks down the
        content and re-checks after each swipe.
        """
        if self.is_text_visible(text, timeout=timeout):
            return True

        size = self.driver.get_window_size()
        centre_x = size["width"] // 2
        start_y = int(size["height"] * 0.75)
        end_y = int(size["height"] * 0.45)

        previous = ""
        for _ in range(max_swipes):
            # Android input avoids UiAutomator2's W3C gesture proxy hanging
            # while a Flutter dropdown overlays a draggable sheet.
            self.driver.execute_script("mobile: shell", {
                "command": "input",
                "args": ["swipe", str(centre_x), str(start_y), str(centre_x), str(end_y), "500"],
                "timeout": 10000,
            })
            if self.is_text_visible(text, timeout=timeout):
                return True
            # Stop as soon as the content stops moving, so a target that is
            # genuinely absent fails fast instead of burning every swipe.
            current = self.driver.page_source
            if current == previous:
                return False
            previous = current
        return False

    def scroll_sheet_to_text_or_fail(self, text: str, max_swipes: int = 10) -> None:
        assert self.scroll_sheet_to_text(text, max_swipes=max_swipes), (
            f"{text!r} never came into view after scrolling the sheet"
        )

    def tap_text(self, text: str, timeout: int | None = None) -> WebElement:
        element = self._wait_for_first_clickable(
            [
                self.accessibility_id(text),
                self.ui_text(text),
                self.ui_desc(text),
                self.ui_text_contains(text),
                self.ui_desc_contains(text),
            ],
            timeout=timeout,
        )
        self._tap_element_center(element)
        return element

    def tap_text_contains(self, text: str, timeout: int | None = None) -> WebElement:
        element = self._wait_for_first_clickable(
            [self.ui_text_contains(text), self.ui_desc_contains(text)], timeout=timeout
        )
        self._tap_element_center(element)
        return element

    def tap_first_visible_text(self, candidates: Iterable[str], timeout: int | None = None) -> str:
        deadline = time.time() + float(timeout or self.config.default_timeout)
        last_error: Exception | None = None
        while time.time() < deadline:
            for text in candidates:
                try:
                    self.tap_text(text, timeout=1)
                    return text
                except Exception as exc:  # noqa: BLE001 - retry candidate selectors
                    last_error = exc
            time.sleep(0.25)
        raise TimeoutException(f"None of these texts became tappable: {list(candidates)}") from last_error

    def scroll_to_text(self, text: str, timeout: int | None = None) -> WebElement:
        # Flutter exposes most labels as content descriptions. UiScrollable's
        # native-text search can sweep to the bottom before trying descriptions,
        # skipping lazily built rows. Check both after each ordinary page swipe.
        deadline = time.monotonic() + max(float(timeout or self.config.default_timeout), 20)
        size = self.driver.get_window_size()
        x = size["width"] // 2
        for start, end in ((0.75, 0.40), (0.40, 0.75)):
            previous = ""
            for _ in range(12):
                try:
                    return self.wait_for_text(text, timeout=0.3)
                except TimeoutException:
                    pass
                if time.monotonic() >= deadline:
                    raise TimeoutException(f"{text!r} did not become visible while scrolling")
                current = self.driver.page_source
                if current == previous:
                    break
                previous = current
                self.driver.swipe(x, int(size["height"] * start),
                                  x, int(size["height"] * end), 450)
        return self.wait_for_text(text, timeout=1)

    def scroll_to_text_contains(self, text: str, timeout: int | None = None) -> WebElement:
        return self.scroll_to_text(text, timeout=timeout)

    def tap_scroll_text(self, text: str, timeout: int | None = None) -> WebElement:
        # scroll_to_text's swipes can leave the list flinging; clicking the
        # element's old bounds then lands on whatever scrolled under it. In
        # Settings that was the theme strip: a stray "Light" + "Forge" tap
        # silently changed the shared QA account's look mid-suite. Settle,
        # re-find, then tap.
        self.scroll_to_text(text, timeout=timeout)
        time.sleep(1.0)
        element = self.wait_for_text(text, timeout=5)
        element.click()
        return element

    def tap_scroll_text_contains(self, text: str, timeout: int | None = None) -> WebElement:
        return self.tap_scroll_text(text, timeout=timeout)

    def edit_texts(self) -> list[WebElement]:
        fields = self.driver.find_elements(*self.ui_class("android.widget.EditText"))
        # QA semantics wrappers also expose EditText. Index fallbacks must
        # count each actual input once, otherwise index 3 clears Password
        # while the caller intends to fill Full name.
        inputs = [field for field in fields if field.get_attribute("clickable") == "true"]
        return inputs or fields

    def type_into_edit_text(self, index: int, value: str) -> None:
        fields = self.edit_texts()
        if index >= len(fields):
            raise NoSuchElementException(
                f"Requested EditText index {index}; only {len(fields)} field(s) visible"
            )
        field = self._nested_edit_text(fields[index]) or fields[index]
        field.click()
        self._clear_if_populated(field)
        is_password = self._is_password_field(field)
        if value and is_password and not self._paste_focused_text(value):
            field.send_keys(value)
        elif value and not is_password and not self._type_focused_text(value):
            field.send_keys(value)
        time.sleep(0.4)
        if value and not is_password and not self._element_or_child_contains(field, value):
            raise TimeoutException(f"Text was not entered into EditText index {index}")

    def type_into_first_empty_edit_text(self, value: str) -> None:
        fields = self.edit_texts()
        if not fields:
            raise NoSuchElementException("No EditText fields visible")
        for field in fields:
            text = (field.text or "").strip()
            if not text:
                field.click()
                field.send_keys(value)
                return
        fields[0].click()
        try:
            fields[0].clear()
        except Exception:  # noqa: BLE001
            pass
        fields[0].send_keys(value)

    def set_signup_password_visibility(self, *, visible: bool) -> None:
        label = "Show password" if visible else "Hide password"
        for _ in range(2):
            self.tap_text(label, timeout=5)
            time.sleep(0.2)

    def _type_focused_text(self, value: str) -> bool:
        try:
            # Android's `input text` path drops a literal exclamation mark.
            # Send a trailing one as Shift+1 so credential values stay exact.
            if value.endswith("!"):
                self.driver.execute_script("mobile: type", {"text": value[:-1]})
                self.driver.press_keycode(8, metastate=1)
            else:
                self.driver.execute_script("mobile: type", {"text": value})
            return True
        except Exception:  # noqa: BLE001 - fall back to Android input command
            escaped = value.replace("%", "%25").replace(" ", "%s")
        try:
            self.driver.execute_script(
                "mobile: shell",
                {"command": "input", "args": ["text", escaped], "timeout": 10000},
            )
            return True
        except Exception:  # noqa: BLE001 - caller falls back to send_keys
            return False

    def _shell_type_focused(self, value: str) -> bool:
        try:
            self.driver.execute_script(
                "mobile: shell",
                {"command": "input", "args": ["text", value], "timeout": 10000},
            )
            return True
        except Exception:  # noqa: BLE001 - caller uses secure fallbacks
            return False

    def _clear_if_populated(self, field: WebElement) -> None:
        try:
            current = (field.get_attribute("text") or "").strip()
            hint = (field.get_attribute("hint") or "").strip()
            if current and current != hint:
                field.clear()
        except Exception:  # noqa: BLE001 - clear is best effort for Flutter fields
            pass

    def _paste_focused_text(self, value: str) -> bool:
        try:
            self.driver.set_clipboard_text(value)
            self.driver.press_keycode(279)
            return True
        except Exception:  # noqa: BLE001 - caller falls back to send_keys
            return False

    def _replace_element_value(self, field: WebElement, value: str) -> bool:
        """Set secure Flutter fields without Android shell punctuation mangling."""
        try:
            target = field
            if (target.get_attribute("password") or "").lower() != "true":
                for child in target.find_elements(
                    *self.ui_class("android.widget.EditText")
                ):
                    if (child.get_attribute("password") or "").lower() == "true":
                        target = child
                        break
            self.driver.execute_script(
                "mobile: replaceElementValue",
                {"elementId": target.id, "text": value},
            )
            return True
        except Exception:  # noqa: BLE001 - clipboard/send_keys remain available
            return False

    def _is_password_field(self, field: WebElement) -> bool:
        if (field.get_attribute("password") or "").lower() == "true":
            return True
        try:
            return any(
                (child.get_attribute("password") or "").lower() == "true"
                for child in field.find_elements(*self.ui_class("android.widget.EditText"))
            )
        except Exception:  # noqa: BLE001 - attribute probing is best effort
            return False

    def _nested_edit_text(self, element: WebElement) -> WebElement | None:
        try:
            children = element.find_elements(*self.ui_class("android.widget.EditText"))
        except Exception:  # noqa: BLE001
            return None
        clickable_children = []
        for child in children:
            try:
                # UiAutomator may include the queried Flutter semantics wrapper
                # in its own descendant result. It accepts click/setValue but
                # does not update the TextEditingController.
                if child.id != element.id and child.is_enabled():
                    clickable_children.append(child)
            except Exception:  # noqa: BLE001
                continue
        return clickable_children[0] if clickable_children else None

    def _edit_text_with_hint(self, hint: str) -> WebElement:
        for field in self.edit_texts():
            if (field.get_attribute("hint") or "").strip() == hint:
                return field
        raise TimeoutException(f"No EditText with hint {hint!r}")

    def _tap_element_center(self, element: WebElement) -> None:
        if (element.get_attribute("clickable") or "").lower() == "false":
            rect = element.rect
            self.driver.execute_script(
                "mobile: clickGesture",
                {
                    "x": int(rect["x"] + (rect["width"] / 2)),
                    "y": int(rect["y"] + (rect["height"] / 2)),
                },
            )
            time.sleep(0.15)
            return
        try:
            element.click()
            time.sleep(0.15)
            return
        except Exception:  # noqa: BLE001 - fall back to coordinate tap below
            pass
        try:
            rect = element.rect
            x = int(rect["x"] + (rect["width"] / 2))
            y = int(rect["y"] + (rect["height"] / 2))
            self.driver.execute_script(
                "mobile: shell",
                {"command": "input", "args": ["tap", str(x), str(y)], "timeout": 10000},
            )
        except Exception:  # noqa: BLE001 - fall back to normal element click
            try:
                element.click()
            except Exception:  # noqa: BLE001
                pass

    def _shell_tap_element_center(self, element: WebElement) -> None:
        rect = element.rect
        x = int(rect["x"] + (rect["width"] / 2))
        y = int(rect["y"] + (rect["height"] / 2))
        self.driver.execute_script(
            "mobile: shell",
            {"command": "input", "args": ["tap", str(x), str(y)], "timeout": 10000},
        )
        time.sleep(0.15)

    def is_qa_visible(self, value: str, timeout: int = 3) -> bool:
        try:
            self.wait_for_qa(value, timeout=timeout)
            return True
        except TimeoutException:
            return False

    def _any_edit_text_contains(self, value: str) -> bool:
        expected = value.strip()
        if not expected:
            return True
        for field in self.edit_texts():
            actual = " ".join(
                item.strip()
                for item in [field.text, field.get_attribute("text")]
                if item and item.strip()
            )
            if expected in actual:
                return True
        return False

    def _element_or_child_contains(self, element: WebElement, value: str) -> bool:
        expected = value.strip()
        if not expected:
            return True
        candidates = [element]
        try:
            candidates.extend(element.find_elements(*self.ui_class("android.widget.EditText")))
        except Exception:  # noqa: BLE001
            pass
        for candidate in candidates:
            actual = " ".join(
                item.strip()
                for item in [candidate.text, candidate.get_attribute("text")]
                if item and item.strip()
            )
            if expected in actual:
                return True
        return False

    def hide_keyboard(self) -> None:
        try:
            self.driver.hide_keyboard()
        except Exception:  # noqa: BLE001 - keyboard may already be hidden
            pass

    def shell(self, command: str, args: list[str] | None = None, timeout: int = 10000):
        return self.driver.execute_script(
            "mobile: shell",
            {"command": command, "args": args or [], "timeout": timeout},
        )

    def seed_gallery_png(self, filename: str, png_bytes: bytes) -> str:
        remote_dir = "/sdcard/Pictures/AppiumQA"
        remote_path = f"{remote_dir}/{filename}"
        try:
            self.shell("mkdir", ["-p", remote_dir], timeout=10000)
        except Exception:  # noqa: BLE001 - directory may already exist
            pass
        self.driver.push_file(remote_path, base64.b64encode(png_bytes).decode("ascii"))
        try:
            self.shell(
                "am",
                [
                    "broadcast",
                    "-a",
                    "android.intent.action.MEDIA_SCANNER_SCAN_FILE",
                    "-d",
                    f"file://{remote_path}",
                ],
                timeout=15000,
            )
        except Exception:  # noqa: BLE001 - picker may still see file after push
            pass
        return remote_path

    def select_first_gallery_photo_from_picker(self) -> None:
        self._allow_photo_picker_permissions()
        deadline = time.time() + 20
        locators = [
            (
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().descriptionContains("Photo taken")',
            ),
            (
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().resourceIdMatches(".*:id/icon_thumbnail")',
            ),
            (
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().resourceIdMatches(".*:id/thumbnail")',
            ),
            (
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().className("android.widget.ImageView").clickable(true)',
            ),
            (
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().className("android.view.View").clickable(true)',
            ),
        ]
        last_error: Exception | None = None
        while time.time() < deadline:
            self._allow_photo_picker_permissions()
            for locator in locators:
                try:
                    elements = self.driver.find_elements(*locator)
                except Exception as exc:  # noqa: BLE001 - try alternate picker layouts
                    last_error = exc
                    continue
                for element in elements:
                    try:
                        rect = element.rect
                        if rect["y"] < 650 or rect["height"] < 60:
                            continue
                        self._click_element_center(element)
                        self._confirm_photo_picker_selection()
                        return
                    except Exception as exc:  # noqa: BLE001 - try the next thumbnail
                        last_error = exc
            time.sleep(0.5)
        raise TimeoutException("No tappable gallery thumbnail found") from last_error

    def upload_gallery_png_via_picker(
        self,
        *,
        trigger_qa_id: str | None,
        trigger_texts: Iterable[str],
        filename: str,
        png_bytes: bytes,
    ) -> None:
        self.seed_gallery_png(filename, png_bytes)
        opened = bool(trigger_qa_id and self.maybe_tap_qa(trigger_qa_id, timeout=5))
        if not opened:
            self.tap_first_visible_text(trigger_texts, timeout=10)
        self.select_first_gallery_photo_from_picker()

    def _allow_photo_picker_permissions(self) -> None:
        for label in (
            "Allow all photos",
            "Allow",
            "While using the app",
            "Select photos",
            "Choose photos",
            "Dismiss",
        ):
            self.maybe_tap(label, timeout=1)

    def _click_element_center(self, element: WebElement) -> None:
        try:
            element.click()
        except Exception:  # noqa: BLE001 - Android Photo Picker Compose nodes may need coordinates
            rect = element.rect
            self.driver.execute_script(
                "mobile: clickGesture",
                {
                    "x": int(rect["x"] + (rect["width"] / 2)),
                    "y": int(rect["y"] + (rect["height"] / 2)),
                },
            )
        time.sleep(0.3)

    def _tap_photo_picker_done(self) -> bool:
        try:
            done_label = self.driver.find_element(
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().text("Done")',
            )
            label_rect = done_label.rect
            candidates = self.driver.find_elements(
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().className("android.view.View").clickable(true)',
            )
            for candidate in candidates:
                rect = candidate.rect
                contains_label = (
                    rect["x"] <= label_rect["x"]
                    and rect["y"] <= label_rect["y"]
                    and rect["x"] + rect["width"] >= label_rect["x"] + label_rect["width"]
                    and rect["y"] + rect["height"] >= label_rect["y"] + label_rect["height"]
                )
                if contains_label:
                    self._click_element_center(candidate)
                    return True
        except Exception:  # noqa: BLE001 - fall back to text candidates below
            pass
        return self.maybe_tap("Done", timeout=1)

    def _confirm_photo_picker_selection(self) -> None:
        deadline = time.time() + 20
        while time.time() < deadline:
            if self.driver.current_package == self.config.app_package:
                return
            if self._tap_photo_picker_done():
                break
            if self.maybe_tap("Add", timeout=1):
                break
            if self.maybe_tap("Select", timeout=1):
                break
            if self.maybe_tap("Choose", timeout=1):
                break
            time.sleep(0.5)

        deadline = time.time() + 30
        while time.time() < deadline:
            if self.driver.current_package == self.config.app_package:
                return
            time.sleep(0.5)

    def assert_any_text_visible(self, *texts: str, timeout: int | None = None) -> str:
        deadline = time.time() + float(timeout or self.config.default_timeout)
        while time.time() < deadline:
            for text in texts:
                if self.is_text_visible(text, timeout=1):
                    return text
            time.sleep(0.25)
        raise AssertionError(f"None of these texts became visible: {texts}")

    def maybe_tap(self, text: str, timeout: int = 2) -> bool:
        try:
            self.tap_text(text, timeout=timeout)
            return True
        except TimeoutException:
            return False

    def maybe_tap_contains(self, text: str, timeout: int = 2) -> bool:
        try:
            self.tap_text_contains(text, timeout=timeout)
            return True
        except TimeoutException:
            return False

    def skip_if_signed_in_session(self) -> None:
        """Signed-out journeys need the welcome screen.

        With APPIUM_NO_RESET=true the suite reuses the device's signed-in QA
        session, so signup / first sign-in / setup specs have no welcome
        screen to start from. Skip them explicitly instead of failing on a
        missing button (run them with APPIUM_NO_RESET=false, which clears
        app data first).
        """
        if not self.config.no_reset:
            return
        deadline = time.time() + 6
        while time.time() < deadline:
            if self.driver.find_elements(*self.ui_desc_contains("Already a member?")) or self.driver.find_elements(
                *self.ui_text_contains("Already a member?")
            ):
                return
            time.sleep(0.5)
        # Not on the welcome screen: the signed-in shell, or a screen pushed
        # on top of it by an earlier spec.
        import pytest

        pytest.skip("Device is signed in (APPIUM_NO_RESET=true); signed-out journey needs a reset session")

    def open_welcome_signup(self) -> None:
        self.skip_if_signed_in_session()
        # Prefer the stable handle. Matching on display copy made the wording
        # load-bearing: retitling the cover for a new type treatment silently
        # cut off every signed-in test. The copy branches stay as a fallback
        # for builds predating the key.
        if self.maybe_tap_qa("qa.welcome.signup_button", timeout=6):
            return
        if self.is_text_visible("Create Account — It’s Free", timeout=8):
            self.tap_text("Create Account — It’s Free")
        elif self.is_text_visible("Create Account", timeout=2):
            self.tap_text("Create Account")
        elif self.is_text_visible("Create", timeout=2):
            self.tap_text_contains("Create")
        elif self.is_text_visible("Already have an account? Sign in", timeout=2):
            try:
                self.driver.back()
                time.sleep(0.5)
            except Exception:  # noqa: BLE001
                pass
            if self.is_text_visible("Create Account", timeout=3):
                self.tap_text("Create Account")

    def open_welcome_signin(self) -> None:
        if self.is_text_visible("Account credentials", timeout=2):
            return
        try:
            self.wait_for_qa("qa.signin.username_field", timeout=2)
            return
        except TimeoutException:
            pass
        self.skip_if_signed_in_session()
        if self.maybe_tap_qa("qa.welcome.signin_button", timeout=6):
            return
        if self.is_text_visible("Sign in and continue your story", timeout=8):
            self.tap_text("Sign in and continue your story")
        elif self.is_text_visible("Already have an account? Sign in", timeout=2):
            self.tap_text("Already have an account? Sign in")
        elif self.is_text_visible("Sign in", timeout=2):
            self.tap_text("Sign in")
        elif self.is_text_visible("SIGN IN", timeout=2):
            self.tap_text("SIGN IN")

    def sign_in_existing_user(self) -> None:
        if self.is_authenticated_surface_visible(timeout=3):
            return
        # With APPIUM_NO_RESET the live app may still show a screen pushed by
        # an earlier spec; pop back to the signed-in shell before assuming
        # the device is signed out (never press back on the welcome screen).
        for _ in range(4):
            if self.is_text_visible("Already a member?", timeout=1) or self.selected_tab() is not None:
                break
            self.press_back()
        if self.is_authenticated_surface_visible(timeout=3):
            return
        self.open_welcome_signin()
        self.assert_any_text_visible(
            "Sign in", "SIGN IN", "Account credentials", timeout=10
        )
        # UiAutomator2 can acknowledge secure-field replacement without
        # updating Flutter's controller. Enter the synthetic credential in
        # visible mode, verify it through the normal text path, then remask it.
        revealed_password = self.maybe_tap("Show password", timeout=2)
        try:
            self.type_into_qa(
                "qa.signin.username_field", self.config.existing_username, timeout=4
            )
            self.type_into_qa(
                "qa.signin.password_field", self.config.existing_password, timeout=4
            )
        except Exception:  # noqa: BLE001 - text-index fallback
            self.type_into_edit_text(0, self.config.existing_username)
            self.type_into_edit_text(1, self.config.existing_password)
        self.hide_keyboard()
        if revealed_password:
            self.maybe_tap("Hide password", timeout=2)
        try:
            self.tap_qa_coordinate("qa.signin.login_button", timeout=4)
        except TimeoutException:
            self.tap_first_visible_text(["Sign in", "SIGN IN"], timeout=10)
        self.accept_terms_if_present(timeout=10)
        self.wait_for_authenticated_surface(timeout=self.config.long_timeout)

    def is_authenticated_surface_visible(self, timeout: int = 3) -> bool:
        return any(
            self.is_text_visible(text, timeout=timeout if index == 0 else 1)
            for index, text in enumerate(
                ["Discover Matches", "qa.nav.discover", "qa.nav.matches", "qa.nav.profile"]
            )
        )

    def wait_for_authenticated_surface(self, timeout: int | None = None) -> str:
        return self.assert_any_text_visible(
            "Discover Matches",
            "qa.nav.discover",
            "qa.nav.matches",
            "qa.nav.profile",
            timeout=timeout,
        )

    def accept_terms_if_present(self, timeout: int = 5) -> bool:
        if not self.is_text_visible("Terms and Conditions", timeout=timeout):
            return False
        if not self.maybe_tap_qa("qa.terms.accept_checkbox", timeout=5):
            self.maybe_tap_contains("I agree to the Terms", timeout=5)
        if not self.maybe_tap_qa("qa.terms.continue_button", timeout=5):
            self.tap_text_contains("I Accept and Continue", timeout=10)
        return True

    def open_tab(self, label: str) -> None:
        nav_id = f"qa.nav.{label.strip().lower()}"
        if self.maybe_tap_qa(nav_id, timeout=2):
            return
        try:
            self.tap_text(label, timeout=6)
        except TimeoutException:
            self.tap_text_contains(label, timeout=6)

    # ------------------------------------------------------------------
    # Social-feature helpers (specs 19-24). They read only real widgets:
    # bottom-navigation tab state comes from Flutter's own "Tab N of 5"
    # nodes, and texts from visible text/content-desc attributes.
    # ------------------------------------------------------------------

    TAB_INDEX = {"today": 1, "discover": 1, "matches": 2, "engage": 3, "profile": 4, "settings": 5}

    def selected_tab(self) -> int | None:
        """1-based index of the selected bottom tab, or None off the shell."""
        nodes = self.driver.find_elements(
            AppiumBy.XPATH, '//*[starts-with(@content-desc, "Tab ") and contains(@content-desc, " of 5")]'
        )
        for node in nodes:
            try:
                if (node.get_attribute("selected") or "").lower() == "true":
                    return int((node.get_attribute("content-desc") or "Tab 0").split()[1])
            except Exception:  # noqa: BLE001 - node went stale mid-transition
                continue
        return None

    def wait_for_tab(self, name: str, timeout: int = 15) -> None:
        expected = self.TAB_INDEX[name.lower()]
        deadline = time.time() + timeout
        last = None
        while time.time() < deadline:
            last = self.selected_tab()
            if last == expected:
                return
            time.sleep(0.4)
        raise AssertionError(f"Expected bottom tab {name!r} (#{expected}) to be selected, got #{last}")

    def press_back(self, settle: float = 1.0) -> None:
        self.driver.back()
        time.sleep(settle)

    def ensure_app_foreground(self) -> None:
        if self.app_state() != 4:
            self.driver.activate_app(self.config.app_package)
            time.sleep(3)

    def go_today(self, max_backs: int = 6) -> None:
        """Pop pushed screens/sheets until the shell is visible, then pick Today.

        Never presses back while the shell is showing: back on Today leaves
        the app by design.
        """
        self.ensure_app_foreground()
        self.dismiss_snackbars()
        for _ in range(max_backs):
            deadline = time.time() + 2.5
            while time.time() < deadline and self.selected_tab() is None:
                time.sleep(0.4)
            if self.selected_tab() is not None:
                break
            if self.driver.find_elements(*self.ui_text_contains("Already a member?")) or self.driver.find_elements(
                *self.ui_desc_contains("Already a member?")
            ):
                raise AssertionError("The device is signed out (welcome screen); sign the QA member back in")
            self.press_back()
            self.ensure_app_foreground()
        self.open_tab("discover")
        self.wait_for_tab("today")

    DECK_TITLES = ("Discover Matches", "Find meaningful verified matches")

    def open_discovery_deck(self) -> None:
        """Open the swipe deck ("Explore").

        With `intentional_dating_enabled` on, bottom tab 1 is Today, not the
        deck. Today's "Explore profiles" / "Explore more profiles" switch to
        the Matches tab, whose "Discover" view embeds the deck
        (matches_list_screen.dart, MatchesView.discover). The Matches tab
        remembers its last view, so pick the Discover chip explicitly.
        """
        self.sign_in_existing_user()
        self.go_today()
        self.open_tab("Matches")
        self.wait_for_tab("matches")
        if not any(self.is_text_visible(t, timeout=2) for t in self.DECK_TITLES):
            chip = self._wait_for_first_present(
                [(AppiumBy.XPATH, '//android.widget.Button[@content-desc="Discover"]')],
                timeout=10,
            )
            self._tap_element_center(chip)
        self.assert_any_text_visible(*self.DECK_TITLES, timeout=25)
        # An empty deck offers its own refresh; use it once so candidates
        # added since the deck loaded (e.g. by the ensure_deck fixture) show.
        if self.is_qa_visible("qa.discovery.empty_state", timeout=2):
            if self.maybe_tap_qa("qa.discovery.state_action_button", timeout=3):
                time.sleep(3)

    def open_matches_view(self, chip: str = "Your matches") -> None:
        """Matches tab, then one of its view chips: Discover / Your matches / Conversations."""
        self.sign_in_existing_user()
        self.go_today()
        self.open_tab("Matches")
        self.wait_for_tab("matches")
        element = self._wait_for_first_present(
            # Flutter exposes the ChoiceChips as Buttons with `selected`.
            [(AppiumBy.XPATH, f'//android.widget.Button[@content-desc="{self._escape(chip)}"]')],
            timeout=15,
        )
        if (element.get_attribute("selected") or "").lower() != "true":
            self._tap_element_center(element)
            time.sleep(0.8)

    def dismiss_sheet(self) -> None:
        """Close a modal bottom sheet by tapping its scrim above the sheet.

        Flutter's "Dismiss" barrier node spans the whole screen, so tapping
        its centre lands on the sheet itself; system back is avoided because
        it also drops the sheet's text field focus.
        """
        size = self.driver.get_window_size()
        self.driver.execute_script(
            "mobile: clickGesture", {"x": size["width"] // 2, "y": int(size["height"] * 0.12)}
        )
        time.sleep(0.8)

    def scroll_into_middle(self, text: str, timeout: int = 40) -> WebElement:
        """Scroll until `text` is visible and away from the bottom bar/banners."""
        self.wait_for_snackbar_gone()
        element = self.scroll_to_text(text, timeout=timeout)
        size = self.driver.get_window_size()
        for _ in range(3):
            rect = element.rect
            centre = rect["y"] + rect["height"] / 2
            if centre < size["height"] * 0.65:
                break
            x = size["width"] // 2
            self.driver.swipe(x, int(size["height"] * 0.6), x, int(size["height"] * 0.35), 900)
            # Let any fling settle: a tap on a moving Flutter list only stops it.
            time.sleep(1.0)
            element = self.wait_for_text(text, timeout=3)
        time.sleep(0.8)  # scroll_to_text's swipes can leave a fling running
        return self.wait_for_text(text, timeout=3)

    def open_settings_entry(self, title: str) -> None:
        self.go_today()
        self.open_tab("Settings")
        self.wait_for_tab("settings")
        self.scroll_into_middle(title)
        self.tap_text(title)

    def open_engage_entry(self, title: str) -> None:
        self.go_today()
        self.open_tab("Engage")
        self.wait_for_tab("engage")
        self.scroll_into_middle(title)
        self.tap_text(title)

    def type_into_hint(self, hint: str, text: str, timeout: int = 10) -> WebElement:
        self.wait_for_snackbar_gone(timeout=4)
        field = self._wait_for_first_present(
            [(AppiumBy.XPATH, f'//android.widget.EditText[contains(@hint, "{self._escape(hint)}")]')],
            timeout=timeout,
        )
        field.click()
        self._clear_if_populated(field)
        if not self._type_focused_text(text):
            field.send_keys(text)
        time.sleep(0.5)
        if not self._element_or_child_contains(field, text):
            raise TimeoutException(f"Text was not entered into the field hinted {hint!r}")
        return field

    def wait_for_snackbar_gone(self, timeout: int = 12) -> None:
        """Clear an in-app notification banner (SnackBar with an "Open" action).

        Banners for seeded counterpart activity sit over the bottom of the
        screen and swallow taps meant for buttons underneath. With an
        accessibility service attached (UiAutomator2) Flutter keeps a SnackBar
        that has an action on screen until it is used, so use it: "Open"
        dismisses the banner and pushes the notification inbox, and back
        returns to the screen under test.
        """
        locator = (AppiumBy.XPATH, '//android.widget.Button[@content-desc="Open" or @text="Open"]')
        deadline = time.time() + timeout
        while time.time() < deadline:
            actions = self.driver.find_elements(*locator)
            if not actions:
                return
            actions[0].click()
            if self.is_text_visible("Read all", timeout=5):
                self.press_back()
            time.sleep(0.5)

    def wait_for_field_hint(self, hint: str, timeout: int = 10) -> WebElement:
        """An EditText whose hint contains `hint`.

        Flutter exposes the hint attribute; a field wrapped in a labelled
        Semantics (the chat composer) reports "<label>\n<hint>".
        """
        return self._wait_for_first_present(
            [(AppiumBy.XPATH, f'//android.widget.EditText[contains(@hint, "{self._escape(hint)}")]')],
            timeout=timeout,
        )

    def dismiss_snackbars(self) -> None:
        """Swipe away any SnackBar still on screen.

        With an accessibility service attached (UiAutomator2), Flutter keeps a
        SnackBar that has an action (e.g. "Report submitted." / Appeal) until
        it is used or dismissed, so one raised by an earlier spec can cover
        the composer or bottom controls of the next. SnackBars are dismissed
        by swiping down (their default dismiss direction).
        """
        locator = (AppiumBy.XPATH, '//*[@dismissable="true" and @live-region!="0"]')
        size = self.driver.get_window_size()
        for _ in range(3):
            bars = self.driver.find_elements(*locator)
            if not bars:
                return
            try:
                rect = bars[0].rect
            except Exception:  # noqa: BLE001 - it closed on its own meanwhile
                continue
            x = rect["x"] + rect["width"] // 2
            y = rect["y"] + rect["height"] // 2
            self.shell("input", ["swipe", str(x), str(y), str(x), str(min(size["height"] - 5, y + 400)), "250"])
            time.sleep(1.0)

    def wait_for_text_gone(self, text: str, timeout: int = 15) -> None:
        deadline = time.time() + timeout
        while time.time() < deadline:
            if not self.is_text_visible(text, timeout=1):
                return
            time.sleep(0.4)
        raise AssertionError(f"{text!r} was still on screen after {timeout}s")

    def visible_labels(self) -> list[str]:
        """Text and content-desc of every displayed node, newline-joined parts split."""
        source = self.driver.page_source
        labels: list[str] = []
        for raw in re.findall(r'(?:text|content-desc)="([^"]+)"', source):
            value = (
                raw.replace("&#10;", "\n").replace("&amp;", "&").replace("&quot;", '"')
                .replace("&lt;", "<").replace("&gt;", ">").replace("&#39;", "'")
            )
            labels.extend(part.strip() for part in value.split("\n") if part.strip())
        return labels

    def element_desc_contains(self, text: str, timeout: int = 10) -> WebElement:
        return self._wait_for_first_present(
            [self.ui_desc_contains(text), self.ui_text_contains(text)], timeout=timeout
        )

    def app_state(self) -> int:
        """Appium app state: 4 foreground, 3 background, 1 not running."""
        return int(self.driver.query_app_state(self.config.app_package))

    def shared_preferences_xml(self) -> str:
        """Flutter shared preferences of the debug build (run-as needs a debuggable app)."""
        return str(
            self.shell(
                "run-as",
                [self.config.app_package, "cat", "shared_prefs/FlutterSharedPreferences.xml"],
                timeout=10000,
            )
        )

    def save_artifact(self, name: str) -> None:
        import os
        from pathlib import Path

        out = Path(os.getenv("QA_RESULTS_DIR", str(Path(__file__).resolve().parents[1] / "results" / "appium")))
        out.mkdir(parents=True, exist_ok=True)
        safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", name)
        try:
            self.driver.save_screenshot(str(out / f"{safe}.png"))
            (out / f"{safe}.xml").write_text(self.driver.page_source, encoding="utf-8")
        except Exception:  # noqa: BLE001 - evidence capture is best effort
            pass

    def _escape(self, text: str) -> str:
        return text.replace('\\', '\\\\').replace('"', '\\"')

    def _wait_for_first_present(
        self, locators: Iterable[tuple[str, str]], timeout: int | None = None
    ) -> WebElement:
        deadline = time.time() + float(timeout or self.config.default_timeout)
        last_error: Exception | None = None
        while time.time() < deadline:
            for locator in locators:
                try:
                    return self.driver.find_element(*locator)
                except Exception as exc:  # noqa: BLE001 - retry alternate locators
                    last_error = exc
            time.sleep(0.25)
        raise TimeoutException("No matching visible text/description found") from last_error

    def _wait_for_first_clickable(
        self, locators: Iterable[tuple[str, str]], timeout: int | None = None
    ) -> WebElement:
        deadline = time.time() + float(timeout or self.config.default_timeout)
        last_error: Exception | None = None
        while time.time() < deadline:
            for locator in locators:
                try:
                    element = self.driver.find_element(*locator)
                    clickable = (element.get_attribute("clickable") or "").lower()
                    element_class = element.get_attribute("class") or ""
                    # Flutter exposes enabled buttons and checkable controls
                    # with clickable=false on recent Android versions. Their
                    # control bounds still accept coordinate activation.
                    semantic_control = element_class in {
                        "android.widget.Button",
                        "android.widget.Switch",
                        "android.widget.CheckBox",
                        "android.widget.RadioButton",
                    }
                    if element.is_enabled() and element.is_displayed() and (
                        clickable != "false" or semantic_control
                    ):
                        return element
                except Exception as exc:  # noqa: BLE001 - retry alternate locators
                    last_error = exc
            time.sleep(0.25)
        raise TimeoutException("No matching tappable text/description found") from last_error


def contains_number(text: str) -> bool:
    return bool(re.search(r"\d", text or ""))


def generated_username(prefix: str = "appium") -> str:
    suffix = str(time.time_ns() % 1_000_000_000_000).zfill(12)
    return f"{prefix}_{suffix}"[:30]
