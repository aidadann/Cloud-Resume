const apiUrl = "http://localhost:7071/api/GetVisitorCount";
async function fetchVisitorCount() {
    const counterElement = document.getElementById('counter');
    try {
        const response = await fetch(apiUrl);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        counterElement.innerText = data.count;
    } catch (error) {
        console.error("Error fetching visitor count. Backend may not be deployed yet:", error);
        counterElement.innerText = "Offline";
    }
}
fetchVisitorCount();