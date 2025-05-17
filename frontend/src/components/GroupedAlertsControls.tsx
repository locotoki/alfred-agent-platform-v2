import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { toast } from '@/components/ui/use-toast';
import { api } from '@/lib/api';

interface GroupedAlertsControlsProps {
  groups: Array<{
    id: string;
    key: string;
    count: number;
  }>;
}

export function GroupedAlertsControls({ groups }: GroupedAlertsControlsProps) {
  const [selectedGroups, setSelectedGroups] = useState<Set<string>>(new Set());
  const queryClient = useQueryClient();

  const mergeMutation = useMutation({
    mutationFn: async (groupIds: string[]) => {
      return await api.post('/api/v1/alerts/groups/merge', { group_ids: groupIds });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alertGroups'] });
      toast({
        title: 'Groups merged successfully',
        description: `${selectedGroups.size} groups have been merged.`,
      });
      setSelectedGroups(new Set());
    },
    onError: (error) => {
      toast({
        title: 'Merge failed',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const unmergeMutation = useMutation({
    mutationFn: async (groupId: string) => {
      return await api.post(`/api/v1/alerts/groups/${groupId}/unmerge`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['alertGroups'] });
      toast({
        title: 'Group unmerged successfully',
      });
    },
  });

  const handleGroupSelection = (groupId: string, checked: boolean) => {
    const newSelection = new Set(selectedGroups);
    if (checked) {
      newSelection.add(groupId);
    } else {
      newSelection.delete(groupId);
    }
    setSelectedGroups(newSelection);
  };

  const handleMerge = () => {
    if (selectedGroups.size < 2) {
      toast({
        title: 'Select at least 2 groups',
        description: 'You need to select at least 2 groups to merge.',
        variant: 'warning',
      });
      return;
    }
    mergeMutation.mutate(Array.from(selectedGroups));
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button
          onClick={handleMerge}
          disabled={selectedGroups.size < 2 || mergeMutation.isPending}
          variant="primary"
        >
          Merge Selected ({selectedGroups.size})
        </Button>
        <span className="text-sm text-muted-foreground">
          Select groups to merge
        </span>
      </div>

      <div className="space-y-2">
        {groups.map((group) => (
          <div key={group.id} className="flex items-center gap-3 p-3 border rounded-lg">
            <Checkbox
              id={group.id}
              checked={selectedGroups.has(group.id)}
              onCheckedChange={(checked) => 
                handleGroupSelection(group.id, checked as boolean)
              }
            />
            <label
              htmlFor={group.id}
              className="flex-1 cursor-pointer flex items-center justify-between"
            >
              <span className="font-medium">{group.key}</span>
              <span className="text-sm text-muted-foreground">
                {group.count} alerts
              </span>
            </label>
            <Button
              size="sm"
              variant="ghost"
              onClick={() => unmergeMutation.mutate(group.id)}
              disabled={unmergeMutation.isPending}
            >
              Unmerge
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
}