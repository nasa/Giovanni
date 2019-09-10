Function val_to_fstr, value, formatted_str

absV = abs(value)
if(absV ge 10000) then formatted_str = string(value,format='(e13.5)') else $
if(absV ge 1000) then formatted_str = string(value,format='(f8.2)') else $
if(absV ge 100) then formatted_str = string(value,format='(f7.2)') else $
if(absV ge 10) then formatted_str = string(value,format='(f6.2)') else formatted_str = string(value,format='(f5.2)')

return, formatted_str
end

PRO no_valid_data, prod1, prod2, xmin, xmax, ymin, ymax, unit1, unit2, warning_png, $
    case_num, nx, timelabel, regionlabel
; this program plots an blank plot with only a warning message on it  
; by Tong Zhu to provide user with proper warning when there is no valid
; pairs of data avalilabe for display within range of [xmin,xmax]. 1/26/07

print,"INFO Starting no_valid_data ..."
print,"INFO subtitle1=",prod1
print,"INFO subtitle2=",prod2
print,"INFO xmin=",xmin," xmax=",xmax," ymin=",ymin," ymax=",ymax
print,"INFO unit1=",unit1," unit2=",unit2
print,"INFO outfile(no_valid_data)=",warning_png
print,"INFO case_num=",case_num," nx=",nx
print,"INFO timelabel=",timelabel," regionlabel=",regionlabel


ny = 150

  ; set the min font width based on user selected window size nx
  fontwidth_min = fix(nx/100)

  fontwidth = fix(nx/100) & if (fontwidth lt fontwidth_min) then fontwidth = fontwidth_min
  fontheight = fontwidth*fontwidth_min/3

set_plot, 'Z'
;   create my own color table, index 1 to 6
    TVLCT, 0, 0, 255, 1 ; blue
    TVLCT, 21, 225, 74, 2 ; green
    TVLCT, 255, 0, 0, 3 ; red
    TVLCT, 232, 221, 2, 4 ; yellow
    TVLCT, 255, 153, 0, 5 ; orange
    TVLCT, 148, 0, 200, 6 ; purple
;   sign the following two colors for background (white) and labels (black)
    TVLCT, 0, 0, 0, 254; black
    TVLCT, 255, 255, 255, 255; white

    device, set_resolution=[nx, ny]
    device, set_character_size = [fontwidth,fontheight]

!p.background=255
!p.color=254

tvlct, red,green,blue, /get
;print,"red: ", red
;print,"green: ", green
;print,"blue: ", blue

 x = findgen(2)
 y = findgen(2)

 plot,x,y, /nodata, XTICKFORMAT="(A1)", YTICKFORMAT="(A1)", color=255

;;; When there are valid data in both data arrays but no valid pair of data is found
;;;print, xmin, xmax, ymin, ymax
; format the min/max values
;;;;;;;;;s_xmin = val_to_fstr(xmin, s_xmin) 
;;;;;;;;;s_xmax = val_to_fstr(xmax, s_xmax)
;;;;;;;;;s_ymin = val_to_fstr(ymin, s_ymin)
;;;;;;;;;s_ymax = val_to_fstr(ymax, s_ymax)

;;;;;;;;;;; old code before 2/5/08 mod
;;;;;;;;;;;range_info_1 = "in the selected spatial and temporal ranges and within range"
;;;;;;;;;;;range_info_2 = "[" + s_xmin + ", " + s_xmax + "] (" + unit1 + ") for the first parameter and"
;;;;;;;;;;;range_info_3 = "[" + s_ymin + ", " + s_ymax + "] (" + unit2 + ") for the second parameter." 

;;; New addition on 2/5/08, common information
;;; spare setting
;;;;range_info_1 = "in spatial range (" + lon_min + "," + lat_min + ") to (" + lon_max + "," + lat_max + ")" 
;;;;range_info_2 = "from " + begin_time + " to " + end_time

range_info_1 = timelabel + "  " + regionlabel

gen_info = "Scatter Plot for " + prod1 + " and " + prod2 + " can not be generated."

if (strlen(gen_info) gt 75) then gen_info = "Scatter Plot for " + prod1 + " and!C" + prod2 + " can not be generated."

;;;;;;;;;;; sample message provided by James on 2/5/08
;;;;;;;;;;; All data are fill values
;;;;;;;;;;; for parameter X
;;;;;;;;;;; in spatial range (-173.0, -30.0) to (-128.5, -1.0) from 31-Dec-2005 to 
;;;;;;;;;;; 31-Dec-2005.

if (case_num ne "NeedMoreSample") then begin

warning_message1 = "All data are fill values"

case case_num of
  "A": begin
         warning_message1 = warning_message1 + " for parameter " + prod1
         xyouts, nx*0.07, ny*0.6, warning_message1, /device, alignment=0
     end
  "B": begin
         warning_message1 = warning_message1 + " for parameter " + prod2
         xyouts, nx*0.07, ny*0.6, warning_message1, /device, alignment=0
     end
  "AB": begin
         warning_message2 = "for both parameters " + prod1 + " and " + prod2
         xyouts, nx*0.07, ny*0.7, warning_message1, /device, alignment=0
         xyouts, nx*0.07, ny*0.6, warning_message2, /device, alignment=0
     end
endcase

endif else begin

warning_message1 = "Inadequate pair of samples (need 2 or more) found"
;warning_message2 = "for parameters " + prod1 + " and " + prod2
xyouts, nx*0.07, ny*0.6, warning_message1, /device, alignment=0
;xyouts, nx*0.07, ny*0.6, warning_message2, /device, alignment=0

endelse

xyouts, nx*0.07, ny*0.5, range_info_1, /device, alignment=0
;xyouts, nx*0.07, ny*0.4, range_info_2, /device, alignment=0
;;; add one more line to make message more clear
xyouts, nx*0.07, ny*0.4, gen_info, /device, alignment=0


;create a png file

 zbuf=tvrd()
 tvlct,r,g,b,/get
 write_png,warning_png,zbuf,r, g, b
 device,/close

end
