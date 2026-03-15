function fetchGlucoseData(url, count, callback, errorCallback) {
    if (!url) {
        errorCallback("No URL configured");
        return;
    }
    
    var apiUrl = url;
    if (!apiUrl.endsWith("/")) {
        apiUrl += "/";
    }
    apiUrl += "sgv.json?count=" + count;

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.length > 0) {
                        callback(data);
                    } else {
                        errorCallback("No data returned");
                    }
                } catch (e) {
                    errorCallback("Invalid JSON");
                }
            } else {
                errorCallback("HTTP " + xhr.status);
            }
        }
    };
    
    xhr.open("GET", apiUrl, true);
    xhr.timeout = 10000;
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
