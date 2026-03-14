function fetchGlucoseData(url, count, callback, errorCallback) {
    if (!url) {
        errorCallback("No URL configured");
        return;
    }
    
    // Construct the URL to get the requested number of entries
    var apiUrl = url;
    if (!apiUrl.endsWith("/")) {
        apiUrl += "/";
    }
    apiUrl += "sgv.json?count=" + count;

    var xhr = new XMLHttpRequest();
    xhr.open("GET", apiUrl, true);
    // Timeout set to 10 seconds
    xhr.timeout = 10000;
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.length > 0) {
                        callback(data);
                    } else {
                        errorCallback("No data returned");
                    }
                } catch (e) {
                    errorCallback("Invalid JSON: " + e.message);
                }
            } else {
                errorCallback("HTTP Error: " + xhr.status);
            }
        }
    };
    
    xhr.ontimeout = function() {
        errorCallback("Timeout connecting to server");
    };
    
    xhr.send();
}

function getTrendArrow(direction) {
    switch(direction) {
        case "DoubleUp": return "⇈";
        case "SingleUp": return "↑";
        case "FortyFiveUp": return "↗";
        case "Flat": return "→";
        case "FortyFiveDown": return "↘";
        case "SingleDown": return "↓";
        case "DoubleDown": return "⇊";
        case "NONE": return "⟷";
        case "NOT COMPUTABLE": return "?";
        case "RATE OUT OF RANGE": return "⯐";
        default: return "";
    }
}

function convertSgv(sgv, targetUnit) {
    if (targetUnit === "mmol/L") {
        return (sgv / 18.0182).toFixed(1);
    }
    return sgv;
}
