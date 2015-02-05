Capture Images from the Command Line
=============
Forked and improved from: http://iharder.net/imagesnap

A command-line tool that lets you capture still images from an iSight or other video source.

Installation
=============
Just add static lib to your project.

Usage
=============

See Example.app

Image Formats
=============
The following image formats are supported and are determined by the filename extension: JPEG, TIFF, PNG, GIF, BMP.

Changes
=============
 * v0.4.0 - Made Static Lib, enabled ARC.
 * v0.3.0 - Removed QTKit dependency and converted application to use AVFoundation instead.
 * v0.2.5 - Added option to delay the first snapshot for some time. Added a time-lapse feature (thanks, Bas Zoetekouw).
 * v0.2.4 - Found bug that caused crash on Mac OS X 10.5 (but not 10.6).
 * v0.2.4beta - Tracking bug that causes crash on Mac OS X 10.5 (but not 10.6).
 * v0.2.3 - Fixed bug that caused all images to be saved as TIFF. Not sure when this bug was introduced.
 * v0.2.2 - Added ability to output jpeg to standard out. Made executable lowercase imagesnap.
 * v0.2.1 - Changed name from ImageCapture to ImageSnap to avoid confusion with Apple's Image Capture application.
 * v0.2 - Multiple file formats (not just TIFF). Faster response.
 * v0.1 - This is the initial release.
