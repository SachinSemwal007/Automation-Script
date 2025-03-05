// ==UserScript==
// @name         DVSA Driving Test Booking Automation (Click on Seat)
// @namespace    http://tampermonkey.net/
// @version      2.13
// @description  Version with 15-second delay, clicks on available seats, popup handling, and stop functionality
// @include      https://driver-services.dvsa.gov.uk/*
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    console.log("Script Loaded and Running");

    const minDelay = 5000; // Minimum delay in milliseconds
    const maxDelay = 10000; // Maximum delay in milliseconds
    const nextWeekDelay = 1000; // Reduced to 1 second for speed
    const weeksToSearch = 4; // Number of weeks to search forward (configurable)
    let currentWeekIndex = 0; // Tracks the current week being checked
    let searchDirection = "forward"; // "forward" or "backward"
    let foundSeat = false; // Flag to stop the loop when a seat is found
    let allAvailableDates = []; // Store all available dates
    let isPopupVisible = false; // Track if popup is visible
    let isScriptRunning = true; // Flag to control script execution (for stopping)

    // Function to stop the script (global for console access)
    window.stopScript = function () {
        isScriptRunning = false;
        console.log("Script stopped manually. To restart, reload the page or call startSearch() manually.");
        showToast("Script stopped manually.");
    };

    function randomIntBetween(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    function randomDelay(callback) {
        const delay = 5000; // Reduced to 5 seconds for faster start after 15s delay
        console.log(`Delaying for ${delay}ms before running callback`);
        setTimeout(() => {
            console.log("Callback executed");
            callback();
        }, delay);
    }

    function showToast(message) {
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.textContent = message;
        document.body.appendChild(toast);

        setTimeout(() => {
            toast.classList.add('show');
        }, 10);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, 3000);
    }

    function scrollToElement(element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function checkForPopup() {
        const popup = document.querySelector('.ui-dialog.ui-corner-all.ui-widget.ui-widget-content.ui-front');
        if (popup) {
            console.log("Popup detected. Checking if it’s blocking...");
            const popupText = popup.textContent || popup.innerText;
            if (popupText.includes("Currently no tests are available") || popupText.includes("Only use the buttons on the web page")) {
                console.log("Non-blocking popup detected (info or warning), ignoring...");
                isPopupVisible = false;
                // Attempt to click "Okay, thanks" if present
                const okayButton = popup.querySelector('button:contains("Okay, thanks")') || popup.querySelector('button');
                if (okayButton) {
                    console.log("Attempting to click 'Okay, thanks' button...");
                    okayButton.click(); // Try to dismiss it automatically
                }
                return false;
            }

            const isVisible = window.getComputedStyle(popup).display !== 'none' && window.getComputedStyle(popup).visibility !== 'hidden';
            const isModal = popup.getAttribute('role') === 'dialog' || popup.querySelector('.ui-dialog-titlebar-close');

            if (isVisible && isModal) {
                console.log("Blocking popup detected. Pausing the script to avoid detection");
                showToast("Blocking popup detected. Please dismiss it manually.");
                isPopupVisible = true;
                return true;
            }
        }
        console.log("No blocking popup detected, proceeding...");
        isPopupVisible = false;
        return false;
    }

    function getWeekRange() {
        // Placeholder - replace with actual logic to get the week range
        const today = new Date();
        const startDate = today.toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' });
        return { startDate: startDate }; // e.g., "24 Feb 2025"
    }

    function step5() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping step5.");
            return;
        }

        console.log('Running step 5...');
        const results = document.querySelector('.test-centre-results');

        if (!results) {
            console.log('Searching for test centers...');
            document.querySelector('#test-centres-submit').click();
        } else {
            console.log('Checking number of test centers found...');
            if (results.children.length < nearestNumOfCentres) {
                document.querySelector('#fetch-more-centres').click();
            }

            // Sleep and search again
            const interval = randomIntBetween(30000, 60000);
            console.log('Sleeping for ' + interval / 1000 + 's');
            setTimeout(() => {
                document.location.href = "https://driver-services.dvsa.gov.uk/";
            }, interval);
        }
    }

    function step6() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping step6.");
            return;
        }

        if (isPopupVisible) {
            console.log("Script paused due to popup. Please dismiss the pop-up manually.");
            return;
        }

        console.log(`Running Step 6 - Week ${currentWeekIndex + 1}/${weeksToSearch}, Direction: ${searchDirection}, Found Seat: ${foundSeat}`);

        // Get the week range
        const weekRange = getWeekRange();
        if (!weekRange) {
            console.log("Could not determine the week range");
            return;
        }

        // Extract month and year from the start date
        const [startDay, startMonth, startYear] = weekRange.startDate.split(' ');
        const month = startMonth;
        const year = startYear;

        // Get available dates from the DOM
        const dateCells = document.querySelectorAll('.day.none, .day.nonenonotif, .view, .slotsavailable');
        console.log("Found date cells:", dateCells.length);
        let availableDates = [];

        dateCells.forEach(cell => {
            // Check if the cell contains a number indicating availability
            const cellText = cell.textContent.trim();
            const availability = parseInt(cellText, 10);
            if (!isNaN(availability) && availability > 0) { // Treat any positive number as an available slot
                const dateLink = cell.querySelector('a'); // Find the link within the cell
                if (dateLink) {
                    availableDates.push({
                        day: new Date(`${cell.getAttribute('data-day') || cellText} ${month} ${year}`).toLocaleString('en-US', { weekday: 'long' }) || 'Unknown Day',
                        date: cellText,
                        availability: availability,
                        link: dateLink
                    });
                    console.log(`Found available slot: ${availability} on ${cellText} ${month} ${year}`);
                }
            }
        });

        if (availableDates.length > 0) {
            foundSeat = true;
            console.log("Available dates this week (real):", availableDates.map(d => `${d.day}, ${d.date} ${month} ${year} (Availability: ${d.availability})`));
            showToast("Seat available! Clicking the first available date...");
            // Click the first available date link
            if (availableDates[0].link) {
                availableDates[0].link.click();
                console.log("Clicked on available date:", availableDates[0].date);
            } else {
                console.log("No clickable link found for the available date.");
            }
            return; // Exit the function to stop further execution
        } else {
            console.log("No available dates found in this week");
            showToast("No dates available");
        }

        console.log(`Current week: ${currentWeekIndex}, Direction: ${searchDirection}`);
        if (!foundSeat) {
            if (searchDirection === "forward" && currentWeekIndex < weeksToSearch - 1) {
                console.log("Moving to next week...");
                currentWeekIndex++;
                step7();
            } else if (searchDirection === "forward" && currentWeekIndex === weeksToSearch - 1) {
                console.log("Reached end of forward search, switching to backward...");
                searchDirection = "backward";
                currentWeekIndex = weeksToSearch - 1; // Start backward from the last forward week
                goToPreviousWeek();
            } else if (searchDirection === "backward") {
                console.log("Looping backward...");
                goToPreviousWeek();
            }
        }
    }

    function step7() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping step7.");
            return;
        }

        if (isPopupVisible) {
            console.log("Script paused due to popup. Please dismiss the pop-up manually.");
            return;
        }

        console.log('Running Step 7 - Direction: ${searchDirection}, Found Seat: ${foundSeat}');
        const nextWeekLink = document.querySelector('#searchForWeeklySlotsNextWeek');

        if (nextWeekLink && !foundSeat) {
            console.log("Next week button found, attempting click...");
            setTimeout(() => {
                const popup = document.querySelector('.ui-dialog.ui-corner-all.ui-widget.ui-widget-content.ui-front');
                if (popup) {
                    console.log('Popup detected. Checking if it’s the warning...');
                    const popupText = popup.textContent || popup.innerText;
                    if (popupText.includes("Only use the buttons on the web page")) {
                        console.log("Warning popup detected, attempting to dismiss...");
                        const okayButton = popup.querySelector('button:contains("Okay, thanks")') || popup.querySelector('button');
                        if (okayButton) okayButton.click();
                        return; // Retry after dismissal
                    }
                    console.log('Blocking popup detected. Pausing the script to avoid detection');
                    showToast("Blocking popup detected. Please dismiss it manually.");
                    isPopupVisible = true;
                    return;
                }

                nextWeekLink.click();
                console.log("Clicked on next week link");
                showToast('Checking availability for next week....');

                setTimeout(step6, 5000); // Reduced to 5 seconds for speed
            }, nextWeekDelay);
        } else {
            console.log("Next week button not found or seat already found");
        }
    }

    function goToPreviousWeek() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping goToPreviousWeek.");
            return;
        }

        console.log("Attempting to go to previous week...");
        const previousWeekButton = document.querySelector('#searchForWeeklySlotsPreviousWeek');
        if (previousWeekButton) {
            console.log("Previous week button found, attempting click...");
            previousWeekButton.click();
            console.log("Clicked on previous week button");
            setTimeout(step6, 5000); // Reduced to 5 seconds for speed
        } else {
            console.log("Previous week button not found! Looping back to start forward search...");
            searchDirection = "forward";
            currentWeekIndex = 0; // Reset to start forward from the beginning
            step7(); // Start the forward search again
        }
    }

    function handlePage() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping handlePage.");
            return;
        }

        console.log('Current page title:', document.title);
        if (checkForPopup()) {
            console.log("Script paused due to popup. Please dismiss the pop-up manually.");
            return;
        }

        console.log("Forcing startSearch for testing...");
        startSearch(); // Force run for testing, bypassing title check
    }

    function startSearch() {
        if (!isScriptRunning) {
            console.log("Script is stopped, skipping startSearch.");
            return;
        }

        console.log("Starting search... Initial state - isScriptRunning:", isScriptRunning, "currentWeekIndex:", currentWeekIndex, "searchDirection:", searchDirection, "foundSeat:", foundSeat);
        currentWeekIndex = 0;
        searchDirection = "forward";
        foundSeat = false;
        step6(); // Kick off the search
    }

    // Add keyboard shortcut to stop the script (Ctrl + Shift + S)
    document.addEventListener('keydown', (event) => {
        if (event.ctrlKey && event.shiftKey && event.key === 'S') {
            stopScript();
            event.preventDefault(); // Prevent default browser behavior
        }
    });

    (function createToastContainer() {
        const style = document.createElement('style');
        style.innerHTML = `
            .toast {
                visibility: hidden;
                min-width: 250px;
                margin-left: -125px;
                background-color: #333;
                color: #fff;
                text-align: center;
                border-radius: 2px;
                padding: 16px;
                position: fixed;
                z-index: 10000;
                left: 50%;
                bottom: 30px;
                font-size: 17px;
            }

            .toast.show {
                visibility: visible;
                -webkit-animation: fadein 0.5s, fadeout 0.5s 2.5s;
                animation: fadein 0.5s, fadeout 0.5s 2.5s;
            }

            @-webkit-keyframes fadein {
                from {bottom: 0; opacity: 0;}
                to {bottom: 30px; opacity: 1;}
            }

            @keyframes fadein {
                from {bottom: 0; opacity: 0;}
                to {bottom: 30px; opacity: 1;}
            }

            @-webkit-keyframes fadeout {
                from {bottom: 30px; opacity: 1;}
                to {bottom: 0; opacity: 0;}
            }

            @keyframes fadeout {
                from {bottom: 30px; opacity: 1;}
                to {bottom: 0; opacity: 0;}
            }
        `;
        document.head.appendChild(style);
    })();

    // Start the script after a 15-second delay to add multiple centers
    window.addEventListener('load', () => {
        console.log("Page loaded, delaying script start by 15 seconds to add multiple centers...");
        setTimeout(() => {
            console.log("Starting script after 15-second delay...");
            randomDelay(handlePage);
        }, 15000); // 15 seconds delay
    });

    setInterval(checkForPopup, 1000); // Check for popup every second
})();
