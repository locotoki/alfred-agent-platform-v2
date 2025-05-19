import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { ThumbsUp, ThumbsDown, MessageSquare } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { toast } from '@/components/ui/use-toast';
import { api } from '@/lib/api';

interface FeedbackPanelProps {
  alertId: string;
  isNoise?: boolean;
  groupId?: string;
  onFeedbackComplete?: () => void;
}

interface FeedbackSubmission {
  alert_id: string;
  group_id?: string;
  feedback_type: 'noise' | 'signal' | 'comment';
  is_noise?: boolean;
  comment?: string;
  metadata?: Record<string, any>;
}

export function FeedbackPanel({
  alertId,
  isNoise,
  groupId,
  onFeedbackComplete
}: FeedbackPanelProps) {
  const [showComment, setShowComment] = useState(false);
  const [comment, setComment] = useState('');
  const queryClient = useQueryClient();

  const feedbackMutation = useMutation({
    mutationFn: async (submission: FeedbackSubmission) => {
      return await api.post('/api/v1/alerts/feedback', submission);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alerts', alertId] });
      if (groupId) {
        queryClient.invalidateQueries({ queryKey: ['alertGroups', groupId] });
      }

      toast({
        title: 'Feedback recorded',
        description: 'Thank you for improving our alerting system',
      });

      setShowComment(false);
      setComment('');
      onFeedbackComplete?.();
    },
    onError: (error) => {
      toast({
        title: 'Failed to submit feedback',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const submitFeedback = (type: 'noise' | 'signal') => {
    const submission: FeedbackSubmission = {
      alert_id: alertId,
      group_id: groupId,
      feedback_type: type,
      is_noise: type === 'noise',
      metadata: {
        initial_classification: isNoise,
        timestamp: new Date().toISOString(),
      },
    };

    feedbackMutation.mutate(submission);
  };

  const submitComment = () => {
    if (!comment.trim()) return;

    const submission: FeedbackSubmission = {
      alert_id: alertId,
      group_id: groupId,
      feedback_type: 'comment',
      comment: comment.trim(),
      metadata: {
        initial_classification: isNoise,
        timestamp: new Date().toISOString(),
      },
    };

    feedbackMutation.mutate(submission);
  };

  return (
    <div className="rounded-lg border p-4 space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium">
          Was this alert useful?
        </h3>
        <span className="text-xs text-muted-foreground">
          {isNoise ? 'AI thinks this is noise' : 'AI thinks this is important'}
        </span>
      </div>

      <div className="flex gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => submitFeedback('signal')}
          disabled={feedbackMutation.isPending}
          className="flex-1"
        >
          <ThumbsUp className="h-4 w-4 mr-2" />
          Useful
        </Button>

        <Button
          variant="outline"
          size="sm"
          onClick={() => submitFeedback('noise')}
          disabled={feedbackMutation.isPending}
          className="flex-1"
        >
          <ThumbsDown className="h-4 w-4 mr-2" />
          Noise
        </Button>

        <Button
          variant="outline"
          size="sm"
          onClick={() => setShowComment(!showComment)}
          disabled={feedbackMutation.isPending}
        >
          <MessageSquare className="h-4 w-4" />
        </Button>
      </div>

      {showComment && (
        <div className="space-y-2 animate-in slide-in-from-top-2">
          <Textarea
            placeholder="Provide additional feedback..."
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            rows={3}
            className="resize-none"
          />
          <div className="flex justify-end gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setShowComment(false);
                setComment('');
              }}
            >
              Cancel
            </Button>
            <Button
              size="sm"
              onClick={submitComment}
              disabled={!comment.trim() || feedbackMutation.isPending}
            >
              Submit
            </Button>
          </div>
        </div>
      )}

      {feedbackMutation.isPending && (
        <div className="flex items-center justify-center py-2">
          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary" />
          <span className="ml-2 text-sm text-muted-foreground">
            Submitting feedback...
          </span>
        </div>
      )}
    </div>
  );
}

// Optimistic update wrapper for immediate UI feedback
export function OptimisticFeedbackPanel(props: FeedbackPanelProps) {
  const queryClient = useQueryClient();
  const [optimisticFeedback, setOptimisticFeedback] = useState<string | null>(null);

  const handleFeedbackComplete = () => {
    props.onFeedbackComplete?.();
    setOptimisticFeedback(null);
  };

  const wrappedPanel = (
    <FeedbackPanel
      {...props}
      onFeedbackComplete={handleFeedbackComplete}
    />
  );

  if (optimisticFeedback) {
    return (
      <div className="rounded-lg border p-4 bg-muted">
        <p className="text-sm text-center">
          Feedback recorded as: <strong>{optimisticFeedback}</strong>
        </p>
      </div>
    );
  }

  return wrappedPanel;
}

// Batch feedback component for multiple alerts
export function BatchFeedbackPanel({
  alertIds,
  groupId
}: {
  alertIds: string[];
  groupId?: string;
}) {
  const [selectedFeedback, setSelectedFeedback] = useState<Record<string, 'noise' | 'signal'>>({});
  const queryClient = useQueryClient();

  const batchMutation = useMutation({
    mutationFn: async (submissions: FeedbackSubmission[]) => {
      return await api.post('/api/v1/alerts/feedback/batch', { submissions });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alerts'] });
      if (groupId) {
        queryClient.invalidateQueries({ queryKey: ['alertGroups', groupId] });
      }

      toast({
        title: 'Batch feedback recorded',
        description: `Updated ${Object.keys(selectedFeedback).length} alerts`,
      });

      setSelectedFeedback({});
    },
  });

  const handleBatchSubmit = () => {
    const submissions: FeedbackSubmission[] = Object.entries(selectedFeedback).map(
      ([alertId, feedbackType]) => ({
        alert_id: alertId,
        group_id: groupId,
        feedback_type: feedbackType,
        is_noise: feedbackType === 'noise',
        metadata: {
          batch: true,
          timestamp: new Date().toISOString(),
        },
      })
    );

    batchMutation.mutate(submissions);
  };

  return (
    <div className="rounded-lg border p-4 space-y-4">
      <h3 className="text-sm font-medium">
        Batch Feedback ({alertIds.length} alerts)
      </h3>

      <div className="space-y-2 max-h-60 overflow-y-auto">
        {alertIds.map((alertId) => (
          <div key={alertId} className="flex items-center gap-2">
            <span className="text-sm flex-1 truncate">{alertId}</span>
            <div className="flex gap-1">
              <Button
                variant={selectedFeedback[alertId] === 'signal' ? 'default' : 'outline'}
                size="xs"
                onClick={() =>
                  setSelectedFeedback(prev => ({ ...prev, [alertId]: 'signal' }))
                }
              >
                <ThumbsUp className="h-3 w-3" />
              </Button>
              <Button
                variant={selectedFeedback[alertId] === 'noise' ? 'default' : 'outline'}
                size="xs"
                onClick={() =>
                  setSelectedFeedback(prev => ({ ...prev, [alertId]: 'noise' }))
                }
              >
                <ThumbsDown className="h-3 w-3" />
              </Button>
            </div>
          </div>
        ))}
      </div>

      <Button
        className="w-full"
        onClick={handleBatchSubmit}
        disabled={Object.keys(selectedFeedback).length === 0 || batchMutation.isPending}
      >
        Submit Feedback ({Object.keys(selectedFeedback).length} selected)
      </Button>
    </div>
  );
}
