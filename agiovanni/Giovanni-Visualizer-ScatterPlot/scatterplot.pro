function get_display_min,min_orig

if( min_orig gt 1.0) then begin
power = fix(alog10(abs(min_orig)))
endif else begin
power = fix(alog10(abs(min_orig)) -1)
endelse
;;;print, "power: ", power

fmin = 10^( float(power) )
;;;print, "fmin: ", fmin

r1 = fix(min_orig/fmin)*fmin
r2 = min_orig - r1
f2 = fmin/10
min_display = r1 + float( floor(r2/f2)*f2 ) - f2

return, min_display
end

function get_display_max,max_orig

if( max_orig gt 1.0) then begin
power = fix(alog10(abs(max_orig)))
endif else begin
power = fix(alog10(abs(max_orig)) -1)
endelse

fmax = 10^( float(power) )

r1 = fix(max_orig/fmax)*fmax
r2 = max_orig - r1
f2 = fmax/10
max_display = r1 + float( ceil(r2/f2)*f2 ) + f2

return, max_display
end

function format_value, value

abs_value = abs(value)
if(abs_value ge 10000) then fmt_value = string(value,format='(e15.7)') else $
if(abs_value ge 1000) then fmt_value = string(value,format='(f10.4)') else $
if(abs_value ge 100) then fmt_value = string(value,format='(f9.4)') else $
if(abs_value ge 10) then fmt_value = string(value,format='(f8.4)') $
                    else fmt_value = string(value,format='(f7.4)')

return, fmt_value
end

function string_breaker,string,len_limit

len = strlen(string)

;print, "input string: ", string, " len: ", len, " len_limit: ", len_limit

if len lt len_limit then begin
    string1 = string
    string2 = ""
    num_of_line = 1
endif else begin
    i = 0
    n = 0
    string_tmp = string
    len_tmp = len
    while i ne -1 do begin
        i = strpos(string_tmp, " ")
        string_tmp = strmid(string_tmp, i+1, len_tmp)
        len_tmp = strlen(string_tmp)
        n = n + i + 1
        if n gt len_limit then break
    endwhile

    string1 = strmid(string,0,n-1)
    string2 = strmid(string,n,len)
    ; to play it safe
    if string2 ne "" then num_of_line = 2 else num_of_line = 1 
endelse

;;;print, "num_of_line: ", num_of_line, "    string1: ", string1, "     string2: ", string2

total = strtrim(string(num_of_line),2) + "##" + string1 + "##" + string2

return, total
end


PRO scatterplot,infile,outfile,p1,p2,dim,xmin,xmax,ymin,ymax,title,subtitle,xlabel,ylabel

print, "INFO (IDL) Starting scatterplot ..."
print, "p1=",p1
print, "p2=",p2
print, "xmin,xmax=",xmin,xmax
print, "ymin,ymax=",ymin,ymax

lnfitting = "yes"
nx = 600
ny = 600

;;
;; Titles and labels
;;

subtitle1 = p1
subtitle2 = p2
xtitle = xlabel
ytitle = ylabel

sdim = dim
;;;print, "sdim: ", sdim


;;
;; Initialize variable and arrays
;;

;-datax = dblarr(sdim)
;-datay = dblarr(sdim)
dataxmean = dblarr(1)
dataymean = dblarr(1)
sumdatax =dblarr(sdim)
sumdatay =dblarr(sdim)
sumdataxx =dblarr(sdim)
sumdatayy =dblarr(sdim)
sumdataxy =dblarr(sdim)
A=dblarr(1)
B=dblarr(1)
CC=dblarr(1)
R2=dblarr(1)
rmse=dblarr(1)
diff=dblarr(1)

;;
;; Read data
;;

fid = ncdf_open(infile)

;; --- Read first variable p1
ncdf_varget, fid, p1, datax

vinq_p1 = ncdf_varinq(fid, p1)
nattrs = vinq_p1.natts
unit1 = "Unitless"
scale1 = 1.0
offset1 = 0.0
fillv1 = -9999.
for k=0, nattrs-1 do begin
    attname = ncdf_attname(fid, p1, k)
    if (attname eq "_FillValue") then ncdf_attget, fid, p1, "_FillValue", fillv1
    if (attname eq "add_offset") then ncdf_attget, fid, p1, 'add_offset', offset1
    if (attname eq "scale_factor") then ncdf_attget, fid, p1, 'scale_factor', scale1
    if (attname eq "units") then begin
        ncdf_attget, fid, p1, 'units', unit1
        unit1 = string(unit1)
    endif
endfor

;; JPAN: would have float underflow error without the double
datax = double(datax)   ; Cast the data value to type double! 11/28/07
fillv1 = double(fillv1)

print,"INFO fill1=",fillv1,"  unit1=",unit1, "  offset1=",offset1, "  scale1=",scale1

;; --- Read second variable p2

ncdf_varget, fid, p2, datay

vinq_p2 = ncdf_varinq(fid, p2)
nattrs = vinq_p2.natts
unit2 = "Unitless"
scale2 = 1.0
offset2 = 0.0
fillv2 = -9999.
for k=0, nattrs-1 do begin
    attname = ncdf_attname(fid, p2, k)
    if (attname eq "_FillValue") then ncdf_attget, fid, p2, "_FillValue", fillv2
    if (attname eq "add_offset") then ncdf_attget, fid, p2, 'add_offset', offset2
    if (attname eq "scale_factor") then ncdf_attget, fid, p2, 'scale_factor', scale2
    if (attname eq "units") then begin
        ncdf_attget, fid, p2, 'units', unit2
        unit2 = string(unit2)
    endif
endfor

datay = double(datay)   ; Cast the data value to type double! 11/28/07
fillv2 = double(fillv2)

print,"INFO fill2=",fillv2,"  unit2=",unit2, "  offset2=",offset2, "  scale2=",scale2

ncdf_close, fid

;
; Scale data if needed
;

index_nonefill=where (((datax(*) ne fillv1) and (datay(*) ne fillv2)), countxy)
print, "countxy=",countxy

if ( offset1 ne 0.0 or scale1 ne 1.0) then begin
    print, "INFO processing scaling for p1",scale1,offset1
    datax(index_nonefill) = datax(index_nonefill)*scale1 - offset1
endif
if ( offset2 ne 0.0 or scale2 ne 1.0) then begin
    print, "INFO processing scaling for p2",scale2,offset2
    datay(index_nonefill) = datay(index_nonefill)*scale2 - offset2
endif


; 5/10/07 TZ if xtitle or ytitle is too long (current len_limit is 50)
; break it into two lines for x/y labaling
; original setting, disabled

;- if (alt_level1 eq "None") then xtitle=xlabel+" ("+unit1+")" else xtitle=xlabel+ " @" + alt_level1 + " ("+unit1+")"
;- if (alt_level2 eq "None") then ytitle=ylabel+" ("+unit2+")" else ytitle=ylabel+ " @" + alt_level2 + " ("+unit2+")"

; Adjust font size relative to size of plot (min. width = 5!) ; James's original
; set the min font width based on user selected window size nx
  fontwidth_min = fix(nx/100)
  
  fontwidth = fix(nx/100) & if (fontwidth lt fontwidth_min) then fontwidth = fontwidth_min
  ;fontheight = fontwidth*5/3
  fontheight = fontwidth*fontwidth_min/3

  ; Set the X and Y margin (number is characters, based on font size)
  x_left = 14
  x_right = 6
  y_bot = 6
  y_top = 10

; in the unit of characters
; original setting
;x_len_limit = fix(nx/fontwidth) - (x_left+x_right) 
;y_len_limit = fix(ny/fontheight) - (y_top+y_bot) 
; new setting to increase the limit a little bit (add buffer) because it's found that
; the first line too short while the second line to long.
buffer_x = 0
buffer_y = 10
x_len_limit = fix(nx/fontwidth + buffer_x) - (x_left+x_right) 
y_len_limit = fix(ny/fontheight + buffer_y) - (y_top+y_bot) 
;;;print, "x_len_limit: ", x_len_limit, " y_len_limit: ", y_len_limit

; check xtitle
total = string_breaker(xtitle,x_len_limit)
pos1 = strpos(total,"##",0)
pos2 = strpos(total,"##",pos1+2)
x_num_of_line = strmid(total,0,pos1)
xt1= strmid(total,pos1+2, pos2-(pos1+2) )
xt2 = strmid(total,pos2+2, strlen(total)-(pos1+4))

; check ytitle
total = string_breaker(ytitle,y_len_limit)
pos1 = strpos(total,"##",0)
pos2 = strpos(total,"##",pos1+2)
y_num_of_line = strmid(total,0,pos1)
yt1 = strmid(total,pos1+2, pos2-(pos1+2) )
yt2 = strmid(total,pos2+2, strlen(total)-(pos1+4))

;;; added index_a and index_b checks on 2/6/08

index_a = where ((datax(*) ne fillv1), countx)
index_b = where ((datay(*) ne fillv2), county)
print,"INFO Original countx=",countx," ","county=",county

case_num = "false"
error_msg = "none"
if (countx eq 0 and county gt 0) then begin
   case_num = "A"
   error_msg = "ERROR One of the variables has all filled values"
endif

if (countx gt 0 and county eq 0) then begin
   case_num = "B"
   error_msg = "ERROR One of the variables has all filled values"
endif

;;; find min/max from data arrays datax and datay (other than their fill values)
;- index_nonfill = where (((datax(*) ne fillv1) and (datay(*) ne fillv2)), countxy)
;-print, "countxy=",countxy

;;; new addition on 2/5/08
if (countxy eq 0) then begin
   case_num = "AB" 
   error_msg = "ERROR No matching pairs found between two the variables"
endif

xmin_data = min(datax(index_nonefill))
xmax_data = max(datax(index_nonefill))
ymin_data = min(datay(index_nonefill))
ymax_data = max(datay(index_nonefill))

print, "INFO x/y min/max option:", xmin,xmax,ymin,ymax
print, "INFO x/y min/max data:", xmin_data,xmax_data,ymin_data,ymax_data
if(xmin ne "None") then xmin_inuse = float(xmin) else xmin_inuse = xmin_data
if(xmax ne "None") then xmax_inuse = float(xmax) else xmax_inuse = xmax_data
if(ymin ne "None") then ymin_inuse = float(ymin) else ymin_inuse = ymin_data
if(ymax ne "None") then ymax_inuse = float(ymax) else ymax_inuse = ymax_data

print, "INFO x/y min/max inuse:", xmin_inuse,xmax_inuse,ymin_inuse,ymax_inuse

;;; 2/5/08 add the following checks per James's suggestion. More informative
;;; information about the missing is provided for the following case:
;;; For parameter A abd B within x/y min/max range selected by user or full data range otherwise,
;;; report the following:
;;; 1. all fill value for A but not for B
;;; 2. all fill value for B but not for A
;;; 3. all fill value for both A and B

xmin_inuse = xmin_inuse - 0.001
xmax_inuse = xmax_inuse + 0.001
ymin_inuse = ymin_inuse - 0.001
ymax_inuse = ymax_inuse + 0.001
index_A = where( (datax(*) ne fillv1) and (datax(*) ge xmin_inuse) and (datax(*) le xmax_inuse), countx )
index_B = where( (datay(*) ne fillv2) and (datay(*) ge ymin_inuse) and (datay(*) le ymax_inuse), county )

;;;### determine "index3" based on inputs xmin, xmax, ymin and ymax
;;;### begin
; index3 is a list of the indices with valid data values for both datax and datay arrays 

index3=where ( ( (datax(*) ne fillv1) and (datay(*) ne fillv2) and (datax(*) ge xmin_inuse) and (datax(*) le xmax_inuse) and (datay(*) ge ymin_inuse) and (datay(*) le ymax_inuse) ), countxy)


;;
;; Call no_valid_data procedure when conditions meet
;;

print,"INFO countx=",countx," ","county=",county

if (countx eq 0 and county gt 0) then begin
   case_num = "A"
   error_msg = "ERROR No data found within the limits range for one of the variables"
endif

if (countx gt 0 and county eq 0) then begin
   case_num = "B"
   error_msg = "ERROR No data found within the limits range for one of the variables"
endif

if (countx eq 0 and county eq 0) then begin
   case_num = "AB"
   error_msg = "ERROR No data found within the limits range for both variables"
endif

if (countxy lt 2) then begin
   case_num = "NeedMoreSample"
   error_msg = "ERROR Not enough matching pairs (minimum of 3 required, found"+string(countxy)+" pairs)"
endif
if (error_msg ne "none") then begin
    print, error_msg
endif

;;;### if index3 has value -1, that means there is no valid values for display. An image with warning message
;;;### will be generated below
;;;;;;; old code before 2/5/08 modification
;;;;;;;if (index3[0] eq -1 or countxy lt 2) then begin
;;;;;;;   case_num = 2
;;;;;;;   no_valid_data, subtitle1,subtitle2,xmin_inuse,xmax_inuse,ymin_inuse,ymax_inuse,unit1,unit2,outfile, case_num,nx 
;;;;;;;   return
;;;;;;;endif


;;;### perform scaling if needed. TZ 1/25/07  -MOVED (jpan)
;- if ( offset1 ne 0.0 or scale1 ne 1.0) then datax(index3) = datax(index3)*scale1 - offset1
;- if ( offset2 ne 0.0 or scale2 ne 1.0) then datay(index3) = datay(index3)*scale2 - offset2

;;;### round up/down max/min value ranges for x/y axes if the original input
;;;### is undefined. Otherwise just take user specified value

if (case_num ne "false") then begin
    print, "WARN No valid data to plot", case_num
    outfile_1 = outfile + ".nodata"
    no_valid_data, subtitle1,subtitle2,xmin_inuse,xmax_inuse,ymin_inuse,ymax_inuse,unit1,unit2,outfile_1, case_num,nx,title,subtitle
    return
endif

print, "outfile="+outfile


;;
;; Continue to plot scatter
;;


if(xmin ne "None") then begin
    min_x = xmin_inuse
endif else begin
    minx = min(datax(index3))
    if ( minx eq 0) then begin
         min_x = minx
    endif else begin
         min_x = get_display_min(minx)
    endelse
endelse

if(xmax ne "None") then begin
    max_x = xmax_inuse
endif else begin
    maxx = max(datax(index3))
    if ( maxx eq 0) then begin
         max_x = maxx
    endif else begin
         max_x = get_display_max(maxx)
    endelse
endelse

if(ymin ne "None") then begin
    min_y = ymin_inuse
endif else begin
    miny = min(datay(index3))
    if ( miny eq 0) then begin
         min_y = miny
    endif else begin
         min_y = get_display_min(miny)
    endelse
endelse

if(ymax ne "None") then begin
    max_y = ymax_inuse
endif else begin
    maxy = max(datay(index3))
    if ( maxy eq 0) then begin
         max_y = maxy
    endif else begin
         max_y = get_display_max(maxy)
    endelse
endelse

;;;print, "min_x: ", min_x, " max_x: ", max_x
;;;print, "min_y: ", min_y, " max_y: ", max_y

; not being used at this moment
;;;intervalsx=fminx
;;;intevalsy=fmaxy

; hardcoded values from the original sample program
;min_x=100
;max_x=800
;intervalsx=50

;min_y=100
;max_y=800
;intevalsy=50

;;;*** begin ***

sumdatax=0.
sumdatay=0.
sumdataxy=0.
sumdataxx=0.
sumdatayy=0.

; TZ 5/3/07 adding calculation of rmse
diff=0.0

sx=0.
sy=0.
sxy=0.
sxx=0.
syy=0.

;;;### the following line exists in Mohan's original code but it seems not being used
;counter=long(1)

sumdatax=total(datax(index3))
sumdatay=total(datay(index3))

sumdataxy = total(datax(index3)*datay(index3))
sumdataxx = total(datax(index3)*datax(index3))
sumdatayy = total(datay(index3)*datay(index3))

if (sumdatax eq 0.) then begin
    CC=0. ; need to be calculated in both cases (lnfitting "yes" and "no")
    R2=0.

    if (lnfitting eq "yes") then begin
    A=0.
    B=0.
; TZ 5/3/07 add calculation of rmse
    rmse=0.0
    endif

endif else begin
 
   CC = (((countxy * sumdataxy) - (sumdatax * sumdatay))/ $
	(sqrt(((countxy*sumdataxx)-(sumdatax*sumdatax))*  $
((countxy*sumdatayy)-(sumdatay*sumdatay)))))

; add R2 based on science requirement update on 5/1/07
; 9/21/2012 JPan Change R2 from abs(CC) to CC*CC
;   R2 = ABS(CC)
   R2 = CC * CC

    if (lnfitting eq "yes") then begin
	A = (((countxy * sumdataxy) - (sumdatax * sumdatay))/ $
             ((countxy * sumdataxx) - (sumdatax * sumdatax)))

  
	B = (sumdatay - (A * sumdatax))/countxy 

; TZ 5/3/07 add calculation of rmse
        diff = total( (datay(index3)-A*datax(index3) - B)*(datay(index3)-A*datax(index3) - B) )
        rmse = sqrt( diff/countxy )
    endif

endelse

;;;*** end ***

CCf = string(CC,format='(f7.4)')
R2f = string(R2,format='(f7.4)')

print, "INFO A=", A, " B=", B, " CC=", CC, " R2=", R2 

if (lnfitting eq "yes") then begin

Af = format_value(A)
Bf = format_value(B)
RMSf = format_value(rmse)

endif

;;;### create plot using Z buffer
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

;window, 0, nx = width, ysize = height, retain = 2
  device, set_resolution=[nx,ny]
  device, set_character_size = [fontwidth,fontheight]

  !x.margin=[x_left,x_right]
  !y.margin=[y_bot,y_top]

!p.background=255
!p.color=254

;;; refernece line but no show
 !X.style=1
 !Y.style=1

; Prepare for the big Title

cs = string(countxy)
len = strlen(cs)
cnt_info = ""
for i=0,len-1 do begin
    char = strmid(cs,i,1)
    if(char ne " ") then cnt_info = cnt_info + char
endfor
cnt_info = "count = " + cnt_info

if (lnfitting eq "yes") then begin ; if ftting line is required

if(B lt 0) then begin
fitting_info = 'Y =' + Af +'X '+Bf ; based on 4/07 request
endif else begin
fitting_info = 'Y =' + Af +'X +'+Bf ; based on 4/07 request
endelse

CC_info = 'Correlation: R ='+ CCf ; based on 4/07 request

rmse_info = 'RMS Error = ' + RMSf

Title = title + '!C' + subtitle + '!C!C!C'

slabel_bot = float(ny - (y_top-1)*fontheight)/float(ny)
slabel_top = slabel_bot + float(2.5*fontheight)/float(ny)
slabel_middle = 0.5*(slabel_bot+slabel_top)
slabel_left = float(x_left*fontwidth)/float(nx)
slabel_right = float(nx-x_right*fontwidth)/float(nx)
;;;print, "x_left*fontwidth: ", x_left*fontwidth, " nx: ", nx
;;;print, "slabel_bot: ", slabel_bot, " slabel_top: ", slabel_top, " slabel_left: ", slabel_left

endif else begin ; if fitting line is not required

;;; draw R-squared only when no line fitting is required
;; 09/22/12 JPan Change to R as agreed by Chris and Bill Teng
;;R2_info = 'R!e2!N ='+ R2f ; based on 5/1/07 request
R2_info = 'R = '+ CCf

slabel_bot = float(ny - (y_top-1)*fontheight)/float(ny)
slabel_left = float(x_left*fontwidth)/float(nx)
slabel_right = float(nx-x_right*fontwidth)/float(nx)

Title = title + '!C' + subtitle + '!C!C!C'

endelse

;;; Number of count (countxy) info printed on the upper right of the image window (same line with CC_info)
;;;print, "countxy: ", countxy

; Start plotting

 plot,[min_x,max_x],[min_y,max_y],xrange=[min_x,max_x],yrange=[min_y,max_y], $
    title=Title, xtitle=xt1 + '!C' + xt2, ytitle=yt1 + '!C' + yt2, $
    ;/device, $
    linestyle = 1, /nodata

 oplot, datax(index3), datay(index3), psym=4, symsize=0.5
 
; define the size of special labels
slabel_size = 1.0
if (lnfitting eq "yes") then begin ; if ftting line is required
xyouts, slabel_left, slabel_top, fitting_info, /normal, color=3, charsize = slabel_size
xyouts, slabel_left, slabel_middle, CC_info, /normal, color=3, charsize = slabel_size
xyouts, slabel_left, slabel_bot, rmse_info, /normal, color=3, charsize = slabel_size
xyouts, slabel_right, slabel_bot, cnt_info, /normal, color=3, charsize = slabel_size, alignment=1
endif else begin
xyouts, slabel_left, slabel_bot, R2_info, /normal, color=3, charsize = slabel_size
xyouts, slabel_right, slabel_bot, cnt_info, /normal, color=3, charsize = slabel_size, alignment=1
endelse

if (lnfitting eq "yes") then begin
t = fltarr(2)
t[0] = !X.crange[0]
t[1] = !X.crange[1]
x=A*t+B
oplot, t,x, color=3, thick=2
endif

;;;### create an output png file
 zbuf=tvrd()
 tvlct,r,g,b,/get
 write_png,outfile,zbuf,r, g, b
device,/close

end
