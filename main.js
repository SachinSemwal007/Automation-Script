// ==UserScript==
// @name         DVSA Driving Test Booking Automation
// @namespace    http://tampermonkey.net/
// @version      2.6
// @description  Automate the driving test booking process with proper delays, pop-up handling and improved date detection
// @include      https://driver-services.dvsa.gov.uk/*
// @grant        none
// ==/UserScript==



(function () {
    'use strict';

    const minDelay = 5000; //Minimum delay in milliseconds
    const maxDelay = 10000;// Maximum delay in milliseconds
    const nextWeekDelay = 3000;
    const maxWeeksToCheck = 16; //check upto 8 weeks(4 months)
    let weeksChecked = 0; //counter for week checked
    let allAvailableDates = []; // store all the available dates
    let isPopupVisible = false; // track if pop up is visble
    let dateFound = false; // Track if a date has been f

    function randomIntBetween(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    function randomDelay(callback) {
        const delay = 4000;
        setTimeout(callback, delay);
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

   // window.addEventListener("load", () => {
  //     alert("Script Is Running");
   // });

    function step1() {
        console.log('Running step 1...');
        const testTypeDropdown = document.querySelector('#businessBookingTestCategoryRecordId');

        if(testTypeDropdown){
           //scrollToElement(testTypeDropdown);

            testTypeDropdown.value = "Tc-B";

            testTypeDropdown.dispatchEvent(new Event("change", { bubbles: true }));
            testTypeDropdown.dispatchEvent(new Event("input", { bubbles: true }));
            testTypeDropdown.dispatchEvent(new Event("click", { bubbles: true }));


            console.log("Option selected");
        } else{
           console.log("Option not found")
        }
    }



    function step2() {
        console.log('Running step 2...');

        const testCentreDropdown = document.querySelector('#favtestcentres');

        if(testCentreDropdown){

            testCentreDropdown.value = "88";

            testCentreDropdown.dispatchEvent(new Event("change", { bubbles: true }));
            testCentreDropdown.dispatchEvent(new Event("input", { bubbles: true }));
            testCentreDropdown.dispatchEvent(new Event("click", { bubbles: true }));

             console.log("Test Centrer Selected:" ,testCentreDropdown.value);
        } else{
           console.log("Test centre dropdown not found")
        }
        }





    function step3() {
        console.log('Running step 3...');

        const noRadio = document.querySelector('#specialNeedsChoice-noneeds');

        if(noRadio){
           noRadio.checked = true;

            noRadio.dispatchEvent(new Event("change", { bubbles: true }));
            noRadio.dispatchEvent(new Event("input", { bubbles: true }));

            console.log("radio button selected");
        } else{
           console.log("radio button not found")
        }
    }



    function step4() {
        console.log('Running step 4...');

        const bookTestbtn = document.querySelector('#submitSlotSearch');
        if (bookTestbtn) {
            bookTestbtn.click();

            console.log("book test button clicked");
        } else{
           console.log("book test button not found")
        }
    }



    function step5() {
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

    function checkForPopup(){
      const popup = document.querySelector('.ui-dialog.ui-corner-all.ui-widget.ui-widget-content.ui-front');

        if(popup){
           console.log("Popup detected. Pausing the script to avoid detection");
            showToast("popup detected. Please dismiss it manually");
            isPopupVisible = true;
            return true;
        }
        isPopupVisible = false;
        return false;
    }

  function showAvailableDatesTable(availableDates) {
    // Create a popup container
    const popup = document.createElement('div');
    popup.style.position = 'fixed';
    popup.style.top = '50%';
    popup.style.left = '50%';
    popup.style.transform = 'translate(-50%, -50%)';
    popup.style.backgroundColor = '#fff';
    popup.style.padding = '20px';
    popup.style.border = '1px solid #ccc';
    popup.style.borderRadius = '8px';
    popup.style.boxShadow = '0 4px 8px rgba(0, 0, 0, 0.2)';
    popup.style.zIndex = '10000';
    popup.style.fontFamily = 'Arial, sans-serif';

    // Add a title
    const title = document.createElement('h3');
    title.textContent = 'Available Test Dates';
    title.style.marginTop = '0';
    popup.appendChild(title);

    // Create a table
    const table = document.createElement('table');
    table.style.width = '100%';
    table.style.borderCollapse = 'collapse';

    // Add table headers
    const headerRow = document.createElement('tr');
    const headerDay = document.createElement('th');
    headerDay.textContent = 'Day';
    headerDay.style.padding = '8px';
    headerDay.style.borderBottom = '2px solid #007bff';
    headerRow.appendChild(headerDay);

    const headerDate = document.createElement('th');
    headerDate.textContent = 'Date';
    headerDate.style.padding = '8px';
    headerDate.style.borderBottom = '2px solid #007bff';
    headerRow.appendChild(headerDate);

    table.appendChild(headerRow);

    // Add table rows for each available date
    availableDates.forEach(date => {
        const row = document.createElement('tr');
        const cellDay = document.createElement('td');
        cellDay.textContent = date.split(' ')[0]; // Extract day (e.g., "Wed")
        cellDay.style.padding = '8px';
        cellDay.style.borderBottom = '1px solid #eee';
        row.appendChild(cellDay);

        const cellDate = document.createElement('td');
        cellDate.textContent = date.split(' ').slice(1).join(' '); // Extract full date (e.g., "30 July 2025")
        cellDate.style.padding = '8px';
        cellDate.style.borderBottom = '1px solid #eee';
        row.appendChild(cellDate);

        table.appendChild(row);
    });

    popup.appendChild(table);

    // Add a close button
    const closeButton = document.createElement('button');
    closeButton.textContent = 'Close';
    closeButton.style.marginTop = '10px';
    closeButton.style.padding = '8px 16px';
    closeButton.style.backgroundColor = '#007bff';
    closeButton.style.color = '#fff';
    closeButton.style.border = 'none';
    closeButton.style.borderRadius = '4px';
    closeButton.style.cursor = 'pointer';

    closeButton.addEventListener('click', () => {
        document.body.removeChild(popup);
    });

    popup.appendChild(closeButton);

    // Append the popup to the body
    document.body.appendChild(popup);
}

    
    function step6(){

        if(isPopupVisible){
          console.log("Script paused due to popup.Please dismiss the popp-up manually.");
            return;
        }

        console.log("Running Step 6");
        const dateCells = document.querySelectorAll('.day.none, .day.nonenonotif');


        let availableDates = [];

        dateCells.forEach(cell => {
            if(cell.classList.contains('slotsavailable')){

                const dateLink = cell.querySelector('a');
                if(dateLink){
                  const dateText = dateLink.textContent.trim();
                    if(dateText){
                      availableDates.push(dateText);
                    }
                }
            }
        });

        if (availableDates.length > 0) {
           console.log("Available dates this week:", availableDates);
            showToast("Available dates this week:" + availableDates.join(', '));

            //store available dates with week number
            allAvailableDates.push({
                week: allAvailableDates.length + 1,
                dates: availableDates

            });


        } else{
           console.log("No available dates found");
           showToast("No dates available");
        }

        //proceed to check the next week
        step7();
    }

  step6();

    function step7(){

        if(isPopupVisible){
          console.log("Script paused due to popup.Please dismiss the popp-up manually.");
            return;
        }

        console.log('Running Step 7');
        const nextWeekLink = document.querySelector('#searchForWeeklySlotsNextWeek');

        if(nextWeekLink && !dateFound){

         setTimeout(() => {

             const popup = document.querySelector('.popup-message');

             if(popup){
               console.log('Popup detected. Pausing the script to avoid detection.');
                 showToast('Popup detected. Please desmiss it manually.');
                 return;
             }

              nextWeekLink.click();
              console.log("Clicked on next week link");
              showToast('Checking availability for next week....');

              //Increment the weeks counter
              weeksChecked++;

              //After clicking on next week, wait for the page to load and re-run step 6
              setTimeout(() =>{
                step6(); //check the avaible dates for next week
              }, 5000); //wait for 5 seconds for the page to load
          }, nextWeekDelay);
        } else{
           console.log("No more weeks to check or reached the limit of 4 months");
           showToast("Finished checking availability for 2 months");

            //Log all the dates in a structured format
            console.log('All Available dates:', JSON.stringify(allAvailableDates, null, 2));

            //Display the dates in a table format in the console
            console.table(allAvailableDates.flatMap((week, index) =>
                week.dates.map(date => ({
                      Week: `Week ${index + 1}`,
                      Date: date
            }))
          ));
        }
    }

 // step7();

   

    function handlePage() {

        if(checkForPopup){
          console.log("Script paused due to popup.Please dismiss the pop-up manually.");
            return;
        }

        switch (document.title) {
            case "Test date selection":
                randomDelay(step6);
                break;
            default:
                console.log('Unknown page title:', document.title);
                break;
        }
    }

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

    // Ensure the script runs after the page is fully loaded
    window.addEventListener('load', () => {
        randomDelay(handlePage);
    });

    setInterval(checkForPopup, 1000); //check for pop up every second
})();
