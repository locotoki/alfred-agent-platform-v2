// Demo script to add YouTube results to localStorage

// Sample result data
const demoResult = {
  run_date: new Date().toISOString(),
  trending_niches: Array(20).fill(null).map((_, i) => ({
    query: `trending nursery rhyme ${i+1}`,
    view_sum: Math.floor(Math.random() * 10000000),
    rsv: Math.random() * 100,
    view_rank: i + 1,
    rsv_rank: Math.floor(Math.random() * 20) + 1,
    score: Math.random() * 100,
    x: Math.random() * 10 - 5,
    y: Math.random() * 10 - 5,
    niche: Math.floor(i / 4)
  })),
  top_niches: [
    {
      query: "Baby Shark Dance",
      view_sum: 15432000,
      rsv: 96.3,
      view_rank: 1,
      rsv_rank: 1,
      score: 98.7
    },
    {
      query: "Wheels on the Bus",
      view_sum: 12345000,
      rsv: 91.2,
      view_rank: 2,
      rsv_rank: 2,
      score: 94.5
    },
    {
      query: "Twinkle Twinkle Little Star",
      view_sum: 9876000,
      rsv: 85.7,
      view_rank: 3,
      rsv_rank: 3,
      score: 89.2
    },
    {
      query: "ABC Song",
      view_sum: 8765000,
      rsv: 82.9,
      view_rank: 4,
      rsv_rank: 4,
      score: 86.3
    },
    {
      query: "Five Little Monkeys",
      view_sum: 7654000,
      rsv: 79.3,
      view_rank: 5,
      rsv_rank: 5,
      score: 82.8
    }
  ],
  visualization_url: "https://example.com/visualization",
  actual_cost: 95.50,
  actual_processing_time: 125.3
};

// Add to localStorage
try {
  console.log('Adding demo results to localStorage...');
  localStorage.setItem('youtube-results', JSON.stringify([demoResult]));
  console.log('Demo results added successfully!');
} catch (err) {
  console.error('Failed to add demo results:', err);
}