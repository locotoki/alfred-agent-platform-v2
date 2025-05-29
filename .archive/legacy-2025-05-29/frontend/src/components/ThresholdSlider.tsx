import React, { useState, useEffect } from 'react';
import { Slider, Typography, Box, Paper, Alert, CircularProgress, Button } from '@mui/material';
import { useFeatureFlag } from '../hooks/useFeatureFlag';

interface ThresholdConfig {
  noise_threshold: number;
  confidence_min: number;
  batch_size: number;
  learning_rate: number;
}

interface ThresholdSliderProps {
  apiUrl?: string;
}

export const ThresholdSlider: React.FC<ThresholdSliderProps> = ({
  apiUrl = '/api/thresholds'
}) => {
  const [thresholds, setThresholds] = useState<ThresholdConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState(false);
  const [saving, setSaving] = useState(false);

  // Feature flag check
  const dynamicThresholdsEnabled = useFeatureFlag('dynamic-thresholds');

  useEffect(() => {
    fetchThresholds();
  }, []);

  const fetchThresholds = async () => {
    try {
      setLoading(true);
      const response = await fetch(apiUrl);
      if (!response.ok) throw new Error('Failed to fetch thresholds');
      const data = await response.json();
      setThresholds(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  const handleThresholdChange = (key: keyof ThresholdConfig, value: number) => {
    if (!thresholds) return;

    setThresholds({
      ...thresholds,
      [key]: value
    });
    setIsDirty(true);
  };

  const saveThresholds = async () => {
    if (!thresholds || !isDirty) return;

    try {
      setSaving(true);
      const response = await fetch(apiUrl, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(thresholds)
      });

      if (!response.ok) throw new Error('Failed to save thresholds');

      const updated = await response.json();
      setThresholds(updated);
      setIsDirty(false);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  if (!dynamicThresholdsEnabled) {
    return null; // Feature is disabled
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" padding={3}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" onClose={() => setError(null)}>
        {error}
      </Alert>
    );
  }

  if (!thresholds) {
    return null;
  }

  return (
    <Paper elevation={2} sx={{ padding: 3, marginTop: 2 }}>
      <Typography variant="h6" gutterBottom>
        Dynamic Threshold Configuration
      </Typography>

      <Box marginY={3}>
        <Typography gutterBottom>
          Noise Threshold: {thresholds.noise_threshold.toFixed(2)}
        </Typography>
        <Slider
          value={thresholds.noise_threshold}
          onChange={(_, value) => handleThresholdChange('noise_threshold', value as number)}
          min={0}
          max={1}
          step={0.05}
          marks
          valueLabelDisplay="auto"
        />
      </Box>

      <Box marginY={3}>
        <Typography gutterBottom>
          Confidence Minimum: {thresholds.confidence_min.toFixed(2)}
        </Typography>
        <Slider
          value={thresholds.confidence_min}
          onChange={(_, value) => handleThresholdChange('confidence_min', value as number)}
          min={0}
          max={1}
          step={0.05}
          marks
          valueLabelDisplay="auto"
        />
      </Box>

      <Box marginY={3}>
        <Typography gutterBottom>
          Batch Size: {thresholds.batch_size}
        </Typography>
        <Slider
          value={thresholds.batch_size}
          onChange={(_, value) => handleThresholdChange('batch_size', value as number)}
          min={1}
          max={1000}
          step={10}
          marks={[
            { value: 1, label: '1' },
            { value: 500, label: '500' },
            { value: 1000, label: '1000' }
          ]}
          valueLabelDisplay="auto"
        />
      </Box>

      <Box marginY={3}>
        <Typography gutterBottom>
          Learning Rate: {thresholds.learning_rate.toFixed(4)}
        </Typography>
        <Slider
          value={thresholds.learning_rate}
          onChange={(_, value) => handleThresholdChange('learning_rate', value as number)}
          min={0.0001}
          max={0.1}
          step={0.0001}
          scale={(x) => x * 1000} // Log scale for better UX
          marks={[
            { value: 0.0001, label: '0.0001' },
            { value: 0.001, label: '0.001' },
            { value: 0.01, label: '0.01' },
            { value: 0.1, label: '0.1' }
          ]}
          valueLabelDisplay="auto"
        />
      </Box>

      <Box display="flex" justifyContent="flex-end" gap={2}>
        <Button
          variant="outlined"
          onClick={fetchThresholds}
          disabled={saving}
        >
          Reset
        </Button>
        <Button
          variant="contained"
          onClick={saveThresholds}
          disabled={!isDirty || saving}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
      </Box>
    </Paper>
  );
};
