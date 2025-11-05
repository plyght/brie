document.addEventListener("DOMContentLoaded", function(event) {
    console.log("Brie Extension content script loaded");
});

function handleMessage(event) {
    if (event.name === "testMessage") {
        console.log("Received message from extension:", event.message);
    }
}

safari.self.addEventListener("message", handleMessage);

