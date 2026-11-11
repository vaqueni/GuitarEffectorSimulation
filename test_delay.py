import numpy as np
import pytest

from delay import apply_guitar_delay_lti, bpm_to_delay_samples


def test_bpm_to_delay_samples_quarter_note():
    # 120 BPM -> quarter note = 0.5s -> 22050 samples at 44100 Hz
    assert bpm_to_delay_samples(fs=44100, bpm=120.0, note="quarter") == 22050


def test_bpm_to_delay_samples_eighth_note_is_half_of_quarter():
    fs, bpm = 44100, 100.0
    quarter = bpm_to_delay_samples(fs, bpm, "quarter")
    eighth = bpm_to_delay_samples(fs, bpm, "eighth")
    assert eighth == pytest.approx(quarter / 2, abs=1)


def test_bpm_to_delay_samples_invalid_note_raises():
    with pytest.raises(ValueError):
        bpm_to_delay_samples(fs=44100, bpm=120.0, note="not_a_note")


def test_apply_guitar_delay_lti_rejects_invalid_mix():
    x = np.zeros(100, dtype=np.float32)
    with pytest.raises(ValueError):
        apply_guitar_delay_lti(x, fs=44100, bpm=120.0, mix=1.5)


def test_apply_guitar_delay_lti_rejects_invalid_feedback():
    x = np.zeros(100, dtype=np.float32)
    with pytest.raises(ValueError):
        apply_guitar_delay_lti(x, fs=44100, bpm=120.0, feedback=1.0)


def test_apply_guitar_delay_lti_rejects_invalid_repeats():
    x = np.zeros(100, dtype=np.float32)
    with pytest.raises(ValueError):
        apply_guitar_delay_lti(x, fs=44100, bpm=120.0, repeats=0)


def test_apply_guitar_delay_lti_output_length_and_dry_signal():
    fs = 1000
    x = np.ones(50, dtype=np.float32)
    repeats = 3

    y, delay_samples = apply_guitar_delay_lti(
        x, fs=fs, bpm=120.0, note="quarter",
        mix=0.5, feedback=0.5, repeats=repeats, dry_gain=1.0,
    )

    assert len(y) == len(x) + delay_samples * repeats
    # Dry signal should be present unattenuated at the start.
    np.testing.assert_allclose(y[:len(x)], x, atol=1e-6)
