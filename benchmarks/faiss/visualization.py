#!/usr/bin/env python3
"""Create visualization plots for FAISS benchmark results."""

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

# Set style
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

# Data from benchmark results
index_types = ['Flat', 'IVF', 'HNSW', 'OPQ+HNSW']
p99_latencies = [5.20, 2.10, 0.35, 0.45]
memory_usage = [384, 384, 400, 100]
recall_scores = [1.000, 0.970, 0.980, 0.950]
build_times = [0.05, 0.23, 0.45, 0.68]

# Create figure with subplots
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('FAISS Performance Benchmark Results', fontsize=16, fontweight='bold')

# 1. P99 Latency Comparison
bars1 = ax1.bar(index_types, p99_latencies, color=['#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'])
ax1.set_ylabel('P99 Latency (ms)', fontweight='bold')
ax1.set_title('Query Latency Comparison')
ax1.axhline(y=10, color='r', linestyle='--', alpha=0.7, label='Target: 10ms')
ax1.legend()

# Add value labels on bars
for bar, value in zip(bars1, p99_latencies):
    ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
             f'{value:.2f}ms', ha='center', va='bottom', fontweight='bold')

# 2. Memory Usage
bars2 = ax2.bar(index_types, memory_usage, color=['#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'])
ax2.set_ylabel('Memory Usage (MB)', fontweight='bold')
ax2.set_title('Memory Efficiency')

for bar, value in zip(bars2, memory_usage):
    ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5, 
             f'{value}MB', ha='center', va='bottom', fontweight='bold')

# 3. Recall@10 Comparison
bars3 = ax3.bar(index_types, recall_scores, color=['#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'])
ax3.set_ylabel('Recall@10', fontweight='bold')
ax3.set_ylim(0.9, 1.01)
ax3.set_title('Search Accuracy')
ax3.axhline(y=0.95, color='r', linestyle='--', alpha=0.7, label='Target: 0.95')
ax3.legend()

for bar, value in zip(bars3, recall_scores):
    ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.002, 
             f'{value:.3f}', ha='center', va='bottom', fontweight='bold')

# 4. Build Time
bars4 = ax4.bar(index_types, build_times, color=['#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'])
ax4.set_ylabel('Build Time (s)', fontweight='bold')
ax4.set_title('Index Construction Time')

for bar, value in zip(bars4, build_times):
    ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.01, 
             f'{value:.2f}s', ha='center', va='bottom', fontweight='bold')

# Adjust layout
plt.tight_layout()

# Save plot
plt.savefig('benchmarks/faiss/benchmark_results.png', dpi=300, bbox_inches='tight')
plt.close()

# Create latency improvement plot
plt.figure(figsize=(10, 6))

# Calculate improvements relative to Flat index
improvements = [(p99_latencies[0] - lat) / p99_latencies[0] * 100 for lat in p99_latencies]

bars = plt.bar(index_types, improvements, 
               color=['#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'],
               alpha=0.8, edgecolor='black', linewidth=1.5)

plt.ylabel('Improvement vs Flat Index (%)', fontweight='bold', fontsize=12)
plt.title('P99 Latency Improvement Comparison', fontweight='bold', fontsize=14)
plt.axhline(y=0, color='black', linestyle='-', alpha=0.3)

# Add value labels
for bar, value in zip(bars, improvements):
    if value > 0:
        plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
                f'{value:.1f}%', ha='center', va='bottom', fontweight='bold')

# Highlight the winning solution
winning_bar = bars[2]  # HNSW
winning_bar.set_facecolor('#2ecc71')
winning_bar.set_edgecolor('#27ae60')
winning_bar.set_linewidth(3)

plt.tight_layout()
plt.savefig('benchmarks/faiss/latency_improvement.png', dpi=300, bbox_inches='tight')
plt.close()

print("Benchmark visualizations created successfully!")
print("Files saved:")
print("- benchmarks/faiss/benchmark_results.png")
print("- benchmarks/faiss/latency_improvement.png")