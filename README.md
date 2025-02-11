# STMO-ZOO : Color transfer using Optimal transportation done right

### Student name : Ju Hyung Lee

![alt text](https://github.com/juhlee/ColorTransfer.jl/blob/ColorTransfer/figs/choosing-color-scheme-368x246.png)

<h2> Welcome to the "ColorTransfer" repository in STMO zoo! </h2>

This final project is categorized as a 'tool', in which I will implement a color transportation in a different way from the one we implemented in the course (Chapter 6: Optimal Transport)!

By saying **"a different way"**, you will see:

- **No sub-sampling** of the input images
- **Clustering** of the color schemes of the original images (K-means clustering)
- **Different** formulas to calculate **color difference** between two images
- Optimal transport between the clustered color schemes **rather than** for all pixels
- Thus, **much faster execution** of the codes!

<h2> Running the code </h2> 

All the necessary codes are in **notebook/colortransfer.jl** (Stand-alone pluto notebook)

![alt text](https://github.com/juhlee/ColorTransfer.jl/blob/ColorTransfer/figs/nutshell.png)

If you run the notebooks/colortransfer.jl code, you will see how the two images in the figure above swap the color schemes!

Of course, you have an option to use images of your own preference (There is a file upload button in the notebook).

Throughout the notebook, there are several Sliders to try out different parameter values to see how they affect the outcome of the color transfer.

Except for the clustering, all of the functions are blazing-fast, so feel free to move around the sliders!

[![Build Status](https://travis-ci.org/MichielStock/STMOZOO.svg?branch=master)](https://travis-ci.org/MichielStock/STMOZOO)[![Coverage Status](https://coveralls.io/repos/github/MichielStock/STMOZOO/badge.svg?branch=master)](https://coveralls.io/github/MichielStock/STMOZOO?branch=master) 
