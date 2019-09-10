/**
 * @this This file contains a single Jasmine test specification for:
 *       UI-BrowserCompatibility-001
 * @param none
 * @returns test status
 * @author Andrey Zasorin
 */

describe("UI-BrowserCompatibility-001",
function() {

	beforeAll(function(done){
			spyOn(window, 'alert');
			window.browserChecker.validate(true);
			setTimeout(function(){				
				done();
			}, 1000)
		});

	it("should summon the browser compatibility alert with any string",
		function() {			
			expect(window.alert).toHaveBeenCalled();
			expect(window.alert).toHaveBeenCalledWith(jasmine.any(String));
		}); // end it()

}); // end describe()
