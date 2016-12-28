MMStretchGestureRecognizers
=====

For context about this repo, check out [this blog post](http://blog.getlooseleaf.com/post/111386290589/using-augmented-reality-code-for-a-better-stretch). These gestures power the clone gestures in [Loose Leaf](https://getlooseleaf.com).

This code provides three gestures that can be used to stretch a UIView using affine transforms. The first attempts to keep the four fingers in exactly the same visible locations on the image, but has trouble when those touches form a concave quad. The remaining two gestures allow for smooth stretching of the UIView.

Run the included example app to try each of the gestures to see their output.

## Are you using these gestures?

Let me know! I'd love to know where PerformanceBezier is using and how it's affecting your apps. Ping me
at [@adamwulf](https://twitter.com/adamwulf)!

## Documentation

View the header files for full documentation.

## Including in your project

1. Link against the included OpenCV framework.
2. Copy the gesture .h and .m files into your project

## License

OpenCV is licensed under BSD: [http://opencv.org/license.html](http://opencv.org/license.html)

This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/">Creative Commons Attribution 3.0 United States License</a>.

<a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/3.0/us/88x31.png" /></a><br />

For attribution, please include:

1. Mention original author "Adam Wulf for Loose Leaf app"
2. Link to https://getlooseleaf.com/opensource/
3. Link to https://github.com/adamwulf/PerformanceBezier



## Support this framework

This framework is created by Adam Wulf ([@adamwulf](https://twitter.com/adamwulf)) as a part of the [Loose Leaf app](https://getlooseleaf.com).

[Buy the app](https://itunes.apple.com/us/app/loose-leaf/id625659452?mt=8&uo=4&at=10lNUI&ct=github) to show your support! :)
