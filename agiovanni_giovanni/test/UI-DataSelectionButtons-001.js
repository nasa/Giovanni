describe( "UI-DataSelectionButtons-001",
	function() {

		beforeAll(function(done){
			setTimeout(function(){
				done();
			}, 1000);
		});

		it("After loading the page, there should be 2 buttons shown, and 'Help' and 'Feedback' links to be present",
			function() {	
				var reset_btn = document.getElementById('sessionDataSelToolbarresetBTN-button').childNodes[0].data;
			  expect(reset_btn).toEqual('Reset');			
				
				var plotdata_btn = document.getElementById('sessionDataSelToolbarplotBTN-button').childNodes[0].data;
				expect(plotdata_btn).toEqual('Plot Data');

				var feedback_lnk = document.getElementById('feedbackLink').innerHTML;
				expect(feedback_lnk).toEqual('Feedback');

				var help_lnk = document.getElementById('helpLink').innerHTML;
				expect(help_lnk).toEqual('Help');
			});

		it("Should show/hide menu on help button click",
			function() {	
				var help_lnk = document.getElementById("helpLink");
        expect(help_lnk).toBeTruthy();
				help_lnk.click();		
				var help_menu = document.getElementById('helpMenu');
				expect(help_menu.style.display).not.toEqual('none');
				help_lnk.click();		
				expect(help_menu.style.display).toEqual('none');
			});
});
