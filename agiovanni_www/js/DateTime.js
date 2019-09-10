/*
 *$Id: DateTime.js,v 1.21 2013/11/14 17:50:02 kbryant Exp $
 *-@@@ Giovanni, $Version$
 */
/**
 * Extends parse() method of Date class in JavaScript. Supports 
 * strings in formats natively supported by Date as well as in
 * ISO8601 date time format.
 * 
 * @this {Date}
 * @param {String} dString The date time string 
 * @returns {Boolean} The outcome of parsing as success (true) or failure (false).
 * @see Date
 * @author M. Hegde 
 */
Date.prototype.parse = function (dString) {
    // Checks whether the input is in a native format of JavaScript's Date object
    //TODO temp fix - force all parse to go through manual parse instead of using Date's inbuilt parse
    // until the date time inconsitencies are fixed.

    var list, minuteOffset = 0;
    //	if (isNaN(dateTime)) {
    // Case of date time format not supported by JavaScript Date object
    // Regular expression of ISO8601 date time format
    var iso8601RegExp = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}).*/;
    if ((list = iso8601RegExp.exec(dString))) {
        // Set the date time elements of the JavaScript Date object
        if (!list[1].match(/^\d{4}$/)) {
            // Year is not a 4 digit number
            return false;
        }

        if (!list[2].match(/^\d{1,2}$/)) {
            // Month is not a 1 or 2 digit number
            return false;
        }
        if (list[2] > 12 || list[2] < 1) {
            // Month being less than 1 or greater than 12
            return false;
        }
        if (!list[3].match(/^\d{1,2}$/)) {
            // Day is not a 1 or 2 digit number
            return false;
        }
        if (!list[4].match(/^\d{1,2}$/)) {
            // Hour is not a 1 or 2 digit number
            return false;
        }
        if (list[4] > 23 || list[4] < 0) {
            // Hour being less than 0 or greater than 23
            return false;
        }
        if (!list[5].match(/^\d{1,2}$/)) {
            // Minute is not a 1 or 2 digit number
            return false;
        }
        if (list[5] > 59 || list[5] < 0) {
            // Minute being less than 0 or greater than 59
            return false;
        }
        if (!list[6].match(/^\d{1,2}$/)) {
            // Second is not a 1 or 2 digit number
            return false;
        }
        if (list[6] > 59 || list[6] < 0) {
            // Second being less than 0 or greater than 59
            return false;
        }
        var maxDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (list[2] == 2) {
            // Test for leap year only if month is Feb
            if (list[1] % 4) {
                // Case of year not divisible by 4; not a leap year
            } else {
                // Case of year divisible by 4
                if (list[1] % 100) {
                    // Case of year divisible by 4 but not by 100; a leap year
                    maxDays[1] = 29;
                } else {
                    // Case of year divisible by 4 and by 100; not a leap year
                    if (list[1] % 400) {
                        // Case of year not divisible by 400; not a leap year
                    } else {
                        // Case of year divisible by 400; a leap year
                        maxDays[1] = 29;
                    }
                }
            }
        }
        // Check if the day of month falls within valid range
        if (list[3] > maxDays[list[2] - 1] || list[3] < 1) {
            // Case of days in a month falling out side the range
            return false;
        }
        this.setUTCFullYear(list[1]);
        this.setUTCHours(list[4], list[5], list[6]);
        var monNum = parseInt(list[2]) - 1;
        // Set the month to 0 (January), which always has 31 days
        this.setUTCMonth(0);
        // Set the day. Now we can be sure that setting the day will not
        // also change the month. (Note: this object is initialized to the 
		// browser's date. If the brower is in February and you call 
		// this.setUTCDate(31), the DateTime object "helpfully" moves the date 
		// forward to March because it knows that February only has 28 or 29
		// days.)
        this.setUTCDate(list[3]);
        // Set the correct month
        this.setUTCMonth(monNum);
        return true;
    } else {
        // Case of date time format not supported by Date object and the unsupported pattern
        return false;
    }
};

/**
 * Returns the ISO8601 representation of date
 * 
 * @memberOf {Date} 
 * @returns {String} A string representing date in ISO8601 format
 * @author M. Hegde
 */
Date.prototype.toISO8601DateString = function () {
    // All date time GES DISC uses is GMT
    var year = this.getUTCFullYear();
    var mon = this.getUTCMonth() + 1;
    var day = this.getUTCDate();
    var str = '' + year + '-' + (mon < 10 ? '0' : '') + mon + '-' +
        (day < 10 ? '0' : '') + day;
    return str;
};

/**
 * Returns the ISO8601 representation of date time
 * 
 * @memberOf {Date} 
 * @return {String} A string representing date time in ISO8601 format
 * @author M. Hegde
 */
Date.prototype.toISO8601DateTimeString = function () {
    // All date time GES DISC uses is GMT
    var year = this.getUTCFullYear();
    var mon = this.getUTCMonth() + 1;
    var day = this.getUTCDate();
    var dateStr = '' + year + '-' + (mon < 10 ? '0' : '') + mon + '-' +
        (day < 10 ? '0' : '') + day;
    var hr = this.getUTCHours();
    var mm = this.getUTCMinutes();
    var ss = this.getUTCSeconds();
    var timeStr = '' + (hr < 10 ? '0' : '') + hr + ':' + (mm < 10 ? '0' : '') +
        mm + ':' + (ss < 10 ? '0' : '') + ss;
    var dateTimeStr = dateStr + 'T' + timeStr;
    return dateTimeStr;
};

/**
 * Returns the custom representation of date and hours
 * 
 * @memberOf {Date} 
 * @return {String} A string representing date + hour + 'hrs'
 * @author K. Bryant
 */
Date.prototype.toISO8601DateHourString = function () {
    // All date time GES DISC uses is GMT
    var year = this.getUTCFullYear();
    var mon = this.getUTCMonth() + 1;
    var day = this.getUTCDate();
    var dateStr = '' + year + '-' + (mon < 10 ? '0' : '') + mon + '-' +
        (day < 10 ? '0' : '') + day;
    var hr = this.getUTCHours();
    var timeStr = '' + (hr < 10 ? '0' : '') + hr + ' hrs';
    var dateTimeStr = dateStr + ' ' + timeStr;
    return dateTimeStr;
};


/**
 * Returns the custom representation of date
 * 
 * @memberOf {Date} 
 * @return {String} A string representing mm/dd/yyyy
 * @author M.Hegde
 */
Date.prototype.toMonthDayYearDateString = function () {
    var year = this.getUTCFullYear();
    var mon = this.getUTCMonth() + 1;
    var day = this.getUTCDate();
    var dateStr = '' + (mon < 10 ? '0' : '') + mon + '/' + (day < 10 ? '0' : '') + day + '/' + year;
    return dateStr;
};

/**
 * Clones the Date object
 * 
 * @memberOf {Date} 
 * @return {Date} Clone of the Date object
 * @author M. Hegde
 */
Date.prototype.clone = function () {
    //Create a new Date object
    var date = new Date();
    //Set the time in the new Date object
    date.setTime(this.getTime());
    return date;
};