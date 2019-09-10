if (typeof giovanni=="undefined") {
  var giovanni = {};
}

// creates namespace(s) under giovanni
giovanni.namespace = function()
{
  var obj;
  for (var i=0; i<arguments.length; i++)
  {
    var list=(""+arguments[i]).split(".");
    obj = giovanni;
    for(var j=(list[0]=="giovanni")?1:0; j<list.length; j++)
    {      
      obj[list[j]] = obj[list[j]] || {};
      obj = obj[list[j]]; 
    }
  }
  return obj;
};  
