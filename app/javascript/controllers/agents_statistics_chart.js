document.addEventListener('DOMContentLoaded', function() {

    // Define contribution types and colors
    const contributionTypes = [
        { key: "creator", label: "Creator", color: "#4e79a7" },
        { key: "contributor", label: "Contributor", color: "#f28e2b" },
        { key: "publisher", label: "Publisher", color: "#e15759" },
        { key: "fundedBy", label: "Funded By", color: "#76b7b2" },
        { key: "copyrightHolder", label: "Copyright Holder", color: "#59a14f" },
        { key: "translator", label: "Translator", color: "#edc949" },
        { key: "endorsedBy", label: "Endorsed By", color: "#af7aa1" }
    ];
    console.log(contributionData)
    // Filter out undefined or zero contributions
    const filteredContributions = contributionTypes.filter(type => contributionData[type.key] && contributionData[type.key] > 0);

    // Calculate total
    const total = filteredContributions.reduce((sum, type) => sum + (contributionData[type.key] || 0), 0);

    // Prepare chart data
    const chartData = {
        labels: filteredContributions.map(type => `${type.label} (${contributionData[type.key]})`),
        datasets: [{
            data: filteredContributions.map(type => contributionData[type.key]),
            backgroundColor: filteredContributions.map(type => type.color),
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