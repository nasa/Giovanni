giovanni.namespace("footer");

giovanni.footer.content = [
      { 
        link: "http://nco.sourceforge.net/",
        tooltip: "netCDF Operator",
        imgSrc: "./img/nco.gif",
        imgWidth: undefined,
        imgHeight: 30,
        imgAlt: "NCO",
        label: "netCDF Operator"
      },
      { 
        link: "http://opendap.org/",
        tooltip: "OPeNDAP",
        imgSrc: "https://www.opendap.org/sites/default/files/OPeNDAP-meatball.png",
        imgWidth: 30,
        imgHeight: 30,
        imgAlt: "",
        label: "OPeNDAP"
      },
      { 
        link: "http://developer.yahoo.com/yui/",
        tooltip: "Yahoo! User Interface Library",
        imgSrc: "https://disc.gsfc.nasa.gov/common/lib/yui/2.9.0/build/assets/skins/sam/yui-logo.png",
        imgWidth: 40,
        imgHeight: 25,
        imgAlt: "YUI",
        label: "YUI"
      },
      { 
        link: "http://openlayers.org/",
        tooltip: "OpenLayers: Free maps for the web",
        imgSrc: "./img/openlayers.gif",
        imgWidth: undefined,
        imgHeight: undefined,
        imgAlt: "OpenLayers",
        label: "OpenLayers"
      },
      {
        link: "http://www.mapserver.org/ogc/",
        tooltip: "MapServer - open source web mapping",
        imgSrc: "./img/mapserver.gif",
        imgWidth: undefined,
        imgHeight: 35,
        imgAlt: "MapServer",
        label: "MapServer"
      },
      {
        link: "https://earthdata.nasa.gov/about/science-system-description/eosdis-components/common-metadata-repository",
        tooltip: "Common Metadata Repository",
        imgSrc: "./img/nasa-logo-png-transparent-4.png",
        imgWidth: 40,
        imgHeight: 35,
        imgAlt: "Common Metadata Repository",
        label: "CMR"
      }
    ];

giovanni.footer.getHTMLContent = function() {
  return $([
    "<div class='bannerElement'>",
    "  <div class='bannerElement bannerLink' style='float:left;'>",
    "      <a href='https://www.nasa.gov/home/' class=;footerLink' target='_blank'>",
    "        <img src='https://disc.gsfc.nasa.gov/images/gui/nasa_footer_logo.png' height='34' alt='NASA' border='0'/>",
    "      </a>",
    "  </div>",
    "  <div class='bannerElement bannerLink'>",
    "      Responsible NASA Official: <a href='mailto:gsfc-help-disc@lists.nasa.gov' class='footerLink'>Angela Li</a>",
    "      <br />",
    "      Web Curator: <a href='mailto:gsfc-help-disc@lists.nasa.gov' class='footerLink'>M. Hegde</a>",
    "      <br />",
    "  </div>",
    "  <div class='bannerElement bannerLink' style='margin-left:20px;'>",
    "      <a class='bannerLink' href='https://www.nasa.gov/about/highlights/HP_Privacy.html' title='NASA Privacy Policies' target='_blank'>Privacy</a>",
    "  </div>",
    "  <div class='bannerElement bannerLink' style='margin-left:20px;' onclick='session.showMenu(event,\"poweredByMenu\");'>Powered By&nbsp;&#9650;",
    "  <table id='poweredByMenu' class='popupMenu poweredByMenu' style='display:none;'>"
    + giovanni.footer.content.map(giovanni.footer.getImageHTML).join("") +
    "  </table>",
    "  </div>",
    "  <div class='bannerElement bannerLink' style='margin-left:20px;'>",
    "      <a class='bannerLink' href='https://disc.gsfc.nasa.gov/contact' target='_blank'>Contact Us</a>",
    "  </div>",
    "</div>"
  ].join("\n"));
};

giovanni.footer.getImageHTML = function(item, index) {
  return "<tr title='"+ item.tooltip + "'><td style='text-align:right;'><a class='poweredBy' href='" + item.link + "' target='_blank'><img class='poweredByIcon' src='" + item.imgSrc + "' width='" + item.imgWidth + "' height='" + item.imgHeight + "'/></a></td><td style='text-align:left;'><a href='" + item.link + "' class='bannerLink' target='_blank'>" + item.label + "</a></td>";
};
