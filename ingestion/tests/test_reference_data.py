from ingestion.reference_data import load_airport_codes, load_carriers, load_tail_numbers


def test_load_airport_codes_returns_non_empty_list_without_nulls():
    codes = load_airport_codes()

    assert len(codes) > 0
    assert all(code is not None for code in codes)
    assert all(isinstance(code, str) and code.strip() != "" for code in codes)


def test_load_carrier_codes_returns_non_empty_list_without_nulls():
    codes = load_carriers()

    assert len(codes) > 0
    assert all(code is not None for code in codes)
    assert all(isinstance(code, str) and code.strip() != "" for code in codes)


def test_load_tail_numbers_returns_non_empty_list_without_nulls():
    tails = load_tail_numbers()

    assert len(tails) > 0
    assert all(tail is not None for tail in tails)
    assert all(isinstance(tail, str) and tail.strip() != "" for tail in tails)


def test_reference_lists_have_no_duplicates():
    assert len(load_airport_codes()) == len(set(load_airport_codes()))
    assert len(load_carriers()) == len(set(load_carriers()))
    assert len(load_tail_numbers()) == len(set(load_tail_numbers()))