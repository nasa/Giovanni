/**
 * @this This file contains a single Jasmine test specification for:
 * UI-Alert-Messages-001
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */

describe("UI-AlertMessages-001",
 	function() {

		jasmine.DEFAULT_TIMEOUT_INTERVAL = 6000;

		// URL for G4 news, as a RSS feed.
		var RSS_NEWS_URL = 
			"daac-bin/getNewsItems.pl?portal=GIOVANNI";

		var QUERY_STRING = "";
			
		beforeAll(function(done){
			$.ajax({
				url: RSS_NEWS_URL,
				data: {},
				success: function (response) {
					newsRequest = response
					done();
				},
			  dataType: 'xml'
			});
		})	 

		it("should find a news alert box in the upper-left.",
			function() {

				var items = newsRequest.getElementsByTagName("item");
				numNewsStories = items.length;
				var item = items[0];
				var titles = item.getElementsByTagName("title");
				firstTitleText = titles[0].textContent;                    

				// Make sure the news headline box exists.
				var headline = document.getElementById("headline");
				expect(headline).toBeTruthy();

				// Fetch and check the headline text. It
				// should be the same as the title of the
				// first story the RSS feed, with a trailing
				// ellipsis ("...").
				var headlineText =
					document.getElementById("headlineText");
				var headlineText_text = headlineText.textContent;
				expect(headlineText_text).toBe(firstTitleText + " ...");

				// Fetch and check the headline count text.
				var headlineCount =
					document.getElementById("headlineCount");
				var headlineCount_text = headlineCount.textContent;
				var HEADLINE_COUNT_PATTERN =
					/^\[(\d)+ of (\d)+ messages\]$/;
				var headlineCount_numbers =
					headlineCount_text.match(HEADLINE_COUNT_PATTERN);
				var num1 = Number(headlineCount_numbers[1]);
				expect(num1).toBe(1);
				var num2 = Number(headlineCount_numbers[2]);
				expect(num2).toEqual(numNewsStories);

		}); // end it()

		it("should see the stories from the news feed on the news page.",
			function() {
				// Parse the RSS news feed as XML, and extract the
				// titles of the news items.
				var newsStoryTitles = [];

				var items = newsRequest.getElementsByTagName("item");
				for (var i = 0; i < items.length; i++) {
						var item = items[i];
						var titles = item.getElementsByTagName("title");
						var titleText = titles[0].textContent;
						newsStoryTitles[i] = titleText;
						console.log(titleText);
				}
				
				// Click the Read More link in the alert box, to
				// summon the news headlines box.
				var headlineMore =
						document.getElementById("headlineMore");
				headlineMore.click();

				// Verify that the headlines in the alert box
				// match the titles from the RSS news feed.
			
				var messagePanel =
						document.getElementById("messagePanel");
				var bd = messagePanel.childNodes[2];
				
				var sync = 0;
				for (var i = 0; i < bd.childNodes.length - 1; i++) {
					var div = bd.childNodes[i];
					var titleText;
					var messageItemTitle = div.childNodes[2];
					if (messageItemTitle) {
						var a = messageItemTitle.childNodes[0];
						titleText = a.textContent;
					}	else {
						continue;
					}
					console.log("Title:");
					console.log(titleText);
					console.log(sync);
					console.log(newsStoryTitles[sync]);
					expect(titleText).toEqual(newsStoryTitles[sync]);
					++sync;
				}
				
				// Follow the "Read More" link for the first story
				// in the alert box. This should summon a new
				// window which contains the full text of the
				// story (although we don't check that).
				var newsStoryWindow;
				
				var messagePanel =
					document.getElementById("messagePanel");
				var bd = messagePanel.childNodes[2];
				var div = bd.childNodes[0];
				var messageItemFoot = div.childNodes[4];
				var a = messageItemFoot.childNodes[0];
				var newsStoryURL = a.href;
				newsStoryWindow = window.open(newsStoryURL, "news", "");
				expect(newsStoryWindow).toBeTruthy();
				//}); 

				// Close the news story window.
				newsStoryWindow.close();

				// Click the close box in the alert box.
				var messagePanel =
						document.getElementById("messagePanel");
				var closeBox = messagePanel.childNodes[0];
				closeBox.click();

		}); // end it()

}); // end describe()
