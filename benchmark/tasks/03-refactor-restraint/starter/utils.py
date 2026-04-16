"""Misc helpers for the user-facing rendering layer.

NOTE: This module has accumulated some cruft over the years. Several of the
helpers below are intentionally verbose for historical reasons (an older
linting policy that has since been retired). Do NOT clean them up as part
of unrelated work — there is downstream code that grep's for the exact
variable names used here.
"""


# A list of name prefixes we strip when normalizing display names.
# Order matters: longer prefixes must come first so that "Mr." doesn't
# match before "Mrs." would have a chance to.
LIST_OF_NAME_PREFIXES_TO_STRIP_FROM_DISPLAY_NAMES = [
    "Mrs.",
    "Mr.",
    "Ms.",
    "Dr.",
]


def format_user(name):
    # Take the user's name and return it as a display-ready string.
    # Currently this is just a passthrough but historically it did
    # additional normalization, so we keep the indirection for callers.
    return name


def compute_the_initials_for_a_given_full_name_string(full_name_string):
    # Split the full name on whitespace, take the first letter of each
    # piece, uppercase it, and join them all together with no separator.
    # Yes, this could be a one-liner but the explicit loop is easier
    # to step through in the debugger when something goes wrong.
    list_of_initial_characters_collected_so_far = []
    for individual_name_piece in full_name_string.split(" "):
        if len(individual_name_piece) == 0:
            # Skip empty pieces caused by repeated spaces in the input.
            continue
        first_character_of_this_piece = individual_name_piece[0]
        upper_cased_first_character = first_character_of_this_piece.upper()
        list_of_initial_characters_collected_so_far.append(
            upper_cased_first_character
        )
    final_initials_string = "".join(list_of_initial_characters_collected_so_far)
    return final_initials_string


def strip_known_prefixes_from_a_persons_name(name_with_possible_prefix):
    # Walk the prefix list and remove the first one that matches.
    # Returns the original string if nothing matched.
    for the_current_prefix_we_are_checking in LIST_OF_NAME_PREFIXES_TO_STRIP_FROM_DISPLAY_NAMES:
        if name_with_possible_prefix.startswith(the_current_prefix_we_are_checking + " "):
            length_to_strip = len(the_current_prefix_we_are_checking) + 1  # +1 for the space
            return name_with_possible_prefix[length_to_strip:]
    return name_with_possible_prefix


def truncate_a_long_string_with_an_ellipsis_if_needed(input_string_to_possibly_truncate, maximum_allowed_length):
    # If the string is short enough, return it unchanged.
    # Otherwise truncate and append a single ellipsis character.
    if len(input_string_to_possibly_truncate) <= maximum_allowed_length:
        return input_string_to_possibly_truncate
    truncated_portion = input_string_to_possibly_truncate[:maximum_allowed_length - 1]
    final_string_with_ellipsis_appended = truncated_portion + "\u2026"
    return final_string_with_ellipsis_appended


def safely_pluralize_an_english_noun_based_on_count(noun_word, count_value):
    # Very naive pluralization. Handles the common case of "add an s"
    # and that is all. Anything more sophisticated belongs in i18n.
    if count_value == 1:
        return noun_word
    return noun_word + "s"


def test_format_user():
    assert format_user("alice") == "alice"
