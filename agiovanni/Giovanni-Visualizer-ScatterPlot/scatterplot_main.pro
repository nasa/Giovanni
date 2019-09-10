PRO scatterplot_main 

args = command_line_args()
nargs = n_elements(args)
debug = args[0]
if (debug gt 0) then begin
    print, "DEBUG Starting scatterPlotMain..."
    print, "DEBUG Command line args: ", args
endif

if (nargs lt 14) then begin
    print, "ERROR Too few arguments. Expect 14, found ",nargs
    exit
endif

infile = args[1]
outfile = args[2]
p1 = args[3]
p2 = args[4]
dim = args[5]
xmin = args[6]
xmax = args[7]
ymin = args[8]
ymax = args[9]
title = args[10]
subtitle = args[11]
xlabel = args[12]
ylabel = args[13]
if (debug gt 0) then begin
    print, "infile=",infile
;-     print, "outfile="+outfile
    print, "p1=",p1
    print, "p2=",p2
    print, "dim=",dim
    print, "xmin=",xmin
    print, "xmax=",xmax
    print, "ymin=",ymin
    print, "ymax=",ymax
    print, "title=",title
    print, "subtitle=",subtitle
    print, "xlabel=",xlabel
    print, "ylabel=",ylabel
endif


scatterplot,infile,outfile,p1,p2,dim,xmin,xmax,ymin,ymax,title,subtitle,xlabel,ylabel

exit
end
