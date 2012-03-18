/**
 *	Methods to generate a w-curve object into a light-box scene.
 **/

/**
 * @fileOverview
 * @name W-Curve.js
 */


var numPts;     // The number of points in the curve
var zDist;      // The distance between two points
var isCurve;    // Holds true if the user supplies a json file for the curve

/* Get the z-increment between points */
function getZ()
{
   return zDist;
}

/* Get the number of points in the curve */
function getNumPts()
{
   return numPts;
}

/* Get the boolean isCurve */
function getIsCurve()
{
   return isCurve;
}

/**
 * Generate curve(s)
 * @param (JSON) data A data JSON object of nodes denoting position and color
 * @param (GLGE group) set The GLGE group to hold the resulting wcurve
 * @param (number) xyMag The magnitude of calculated x and y values from W-cirve
 * @param (number) zInc The spacing of the codons determined by the z increment.
 **/
var generate_wcurve=function(data, set, xyMag, zMag){
	var positions=[];                // The (z,y,x) coordinate of a node
	var colors=[];                   // The (red,green,blue,alpha) color weight of a node
	size = data.length-1;

	/*
     * The z increment is constant for a wcurve, so iterate
     * through 10000 points with a step size of 1.  
     * Since this z increment is constant, we are able
     * to use it to locate a specific node by an offset
     */

	for(var zInc = 0; zInc<data.length-1; zInc++){

		var currentNode = data[zInc];
		var nextNode = data[zInc+1];

		var x1 = currentNode[0]*xyMag;
		var y1 = currentNode[1]*xyMag;
		var r1 = currentNode[2];
		var g1 = currentNode[3];
		var b1 = currentNode[4];

		var x2 = nextNode[0]*xyMag;
		var y2 = nextNode[1]*xyMag;
		var r2 = nextNode[2];
		var g2 = nextNode[3];
		var b2 = nextNode[4];

		//Draw line between two floating points
		positions.push(zInc*zMag);positions.push(y1);positions.push(x1);
		positions.push((zInc+1)*zMag);positions.push(y2);positions.push(x2);

		//RGBa Color Scheme- vertex to vertex
		colors.push(0); colors.push(0);colors.push(255); colors.push(1); //defaulting to blue for now
		colors.push(0); colors.push(0);colors.push(225); colors.push(1);
	}

	//put curve into scene
	var line=(new GLGE.Object).setDrawType(GLGE.DRAW_LINESTRIPS);
	lineMesh=(new GLGE.Mesh).setPositions(positions).setVertexColors(colors);
	line.setMesh(lineMesh);
	line.setMaterial((new GLGE.Material).setShadeless(true));
	line.setZtransparent(true);
	set.addChild(line);
}

/**
 * Change line color of an offset of the curve.
 * @param (number) lineNumber A data JSON object of nodes denoting position and color
 * @param (number) r Red rgb value 0-255
 * @param (number) g Green rgb value 0-255
 * @param (number) b Blue rgb value 0-255
 **/
function setLineColor(lineNumber,r,g,b){
	var gl=renderer.gl;
	gl.bindBuffer(gl.ARRAY_BUFFER, lineMesh.GLbuffers["color"]);
	gl.bufferSubData(gl.ARRAY_BUFFER,lineNumber*32,new Float32Array([r,g,b,1,r,g,b,1]));
}

/**
 * Change line color of an offset of the curve.
 * @param (number) lineNumber A data JSON object of nodes denoting position and color
 * @param (number) r Red rgb value 0-255
 * @param (number) g Green rgb value 0-255
 * @param (number) b Blue rgb value 0-255
 **/

jsonToWCurve=function(Url, set){
	var xmlHttp = null;

	try{
		xmlHttp = new XMLHttpRequest();
		xmlHttp.onreadystatechange = function(){
         if(xmlHttp.readyState==4)
         {
			      try
               {
                  curve = eval('('+xmlHttp.responseText+')');              // Try to evaluate the json file
                  isCurve = 1;
               }
               catch(e1)
               {
                  alert("Invalid curve, please try again");
                  isCurve=0;                                               // Mark the curve as invalid
               }
               if(isCurve==1)                                              // Generate the curve if it is valid
               {
                  numPts=curve.length;
                  zDist=0.03125;
			         generate_wcurve(curve,set,0.8, zDist);		//Change z value if want
               }

         }
		}

		xmlHttp.open( "GET", Url, true );
		xmlHttp.send( null );

	} catch (e) {
      isCurve = 0;
		alert("An exception occurred in the script. Error name: " + e.name
		+ ". Error message: " + e.message);
	}
}

fastaToWCurve=function(curve, set){
                  numPts=curve.length;
                  zDist=0.03125;
		  generate_wcurve(curve,set,0.8, zDist);		//Change z value if want
}

