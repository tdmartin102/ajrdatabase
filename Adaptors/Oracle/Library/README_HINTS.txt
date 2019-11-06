An Explanation for what is here and why

The Oracle Libraries all have @rpath set  They all point to the version specific libraries

In the distribution for instance there is 

libclntsh.dylib which is a symbolic link to libclntsh.dylib.19.1

In the libclntshcore.dylib.19.1 library the @rpath is set to /libclntsh.dylib.19.1

So when the adaptor launches it is going to evaluate that dependency and look for libclntsh.dylib.19.1

We set the Adaptor run path to @loader_path/../Resources

This means @rpath with get expanded to that and it will again look for libclntsh.dylib.19.1 in Resources.

This means all the intedependant libraries will be copied to /Resources and all should load.  There is no reason whatsoever to copy the symbolic links to Resources as they would not be used.  HOWEVER  For some reason I can not fathom Xcode will NOT link correctly to libclntsh.dylib.19.1.  Rather put a deeper dent in my forehead the simple solution was to COPY libclntsh.dylib.19.1 to libclntsh.dylib  as it links to that just fine.  Also xCode will not allow you to specify a symbolic link as a library, it very un-helpfully follows the symbolic link which then causes the link to fail.

Bottom line, this is a cludge, but it works.  So whenever the library versions are upgraded you should follow this basic idea.