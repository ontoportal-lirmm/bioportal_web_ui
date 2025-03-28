document.addEventListener('DOMContentLoaded', function() {

    // Calculate totals and percentages
    const total = contributionData.creator + contributionData.contributor + (contributionData.publisher || 0);
    const creatorPercent = Math.round((contributionData.creator / total) * 100);
    const contributorPercent = Math.round((contributionData.contributor / total) * 100);
    const publisherPercent = 100 - creatorPercent - contributorPercent;
    
    // Chart data configuration
    const chartData = {
        labels: [
            `Creator (${contributionData.creator})`, 
            `Contributor (${contributionData.contributor})`,
            `Publisher (${contributionData.publisher})`
        ],
        datasets: [{
            data: [
                contributionData.creator, 
                contributionData.contributor,
                contributionData.publisher || 0
            ],
            backgroundColor: [
                '#4e79a7', // creator color
                '#f28e2b', // contributor color
                '#e15759'  // publisher color
            ],
            borderWidth: 1,
            borderColor: '#fff'
        }]
    };
    
    // Create the chart
    const ctx = document.getElementById('contributionChart').getContext('2d');
    const contributionChart = new Chart(ctx, {
        type: 'pie',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        boxWidth: 20,
                        padding: 20,
                        font: {
                            size: 14
                        }
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const label = context.label || '';
                            const value = context.raw;
                            const percentage = Math.round((value / total) * 100);
                            return `${label}: ${percentage}% (${value})`;
                        }
                    }
                }
            }
        }
    });
});