### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 03f007fe-ed84-4ee4-a806-5239843c0391
using  Images , PlutoUI , Colors, ImageIO, LinearAlgebra, Distributions ,Clustering, Test

# ╔═╡ c3c61b29-ddc7-4638-9350-8ce945326d27
md"""
## Final Project: Color transfer using optimal transportation done right

##### Project by Ju Hyung Lee
"""

# ╔═╡ adf59de3-bc73-4d4c-9293-47a2f8569ee5
begin
	try
		imresize(load("../figs/colors_everywhere.jpg"), (350, 450))
	catch
		imurl = "https://github.com/juhlee/imagebank/blob/main/colors_everywhere.jpg?raw=true"
		imresize(load(download(imurl)), (350, 450))
	end
end

# ╔═╡ 877f1fc5-2acd-48ad-87e3-0f28d9c9c9c7
TableOfContents(title="Table of Contents 🔬", depth=2, aside=false)

# ╔═╡ 7d867d3b-ff9b-42dd-818d-c314a977b448
md""" --- """

# ╔═╡ 03ad0574-699b-4046-863e-611e1a058d82
md"""
##

In chapter 6, we learned the concept of **optimal transportation**, and saw that **color transfer** is one of the applications (we had an exercise on it).

!!! note "Color Transfer Problem 🟥🟧🟨🟩🟦🟪"

	Given the RGB representation of the pixels of two images (X1,X2) and a **cost** over the colors, transfer the color scheme of image 2 to image 1.
"""

# ╔═╡ fde7a4f2-5051-4f3a-859a-843d5d67f38e
md"""
##### What to expect different from the one we implemented in the course?

- The images will be processed in the form of an **Array** (Height x Width x Channels) instead of a complete dependence on the package Colors.jl.
- The color schemes in the images are **clustered** = instead of the whole pixels, only the clustered color schemes go through optimal transportation.
- Thus, codes run **much faster** even **without sub-sampling** of the images.
- Different ways to calculate the color differences **(distances)**
- Different **weights** assigned to each pixels, whereas we gave an uniform distribution in the course.
"""

# ╔═╡ 2aea58e2-9168-43ff-bdd0-dcd7e6ee0339
md""" --- """

# ╔═╡ 3a9db4da-22de-4b49-9630-efc997f2e3b0
md"""
## 0. Load Sample images

By default, you will use two photos in the **figs/** folder  in this project.

The two sample photos below are taken by myself, showing the cityscapes of Seoul in South Korea:

- The first image was taken during daytime. 🏙️
- The second one was taken during sunset. 🌇

How would the **first image** look like during **sunset**? 

How would the **second image** look like during **daytime**?

Could this project predict those situations well through the color transport using optimal transport?
"""

# ╔═╡ dc7c112b-7213-4746-b86e-8cbbb8130a01
md"""
---
"""

# ╔═╡ 69c0bee8-3947-4928-856d-454e5d693492
md"""
#### 0.1. Or, use images of your own preference! 

- To make things convenient, I have made a file upload box below.

- You can load different images that you would like to try out!

!!! danger "⛔ Attention! ⛔"

	**Please first place the desired images in the following path "ColorTransfer.jl/figs/" before selecting them using the filepicker below.**

- Due to limitations in PlutoUI and julia, the filepath of selected images could not be fully tracked (Apologize... I did my best here). 

- You may doubt the point of using FilePicker() if the files had to be transferred to a certain directory before selecting it, but I wanted to try the GUI features in pluto notebook..
"""

# ╔═╡ 4118339f-b3a1-4d89-8bbc-54fae475ae4c
md"""
#### Select image 1
**By default, ColorTransfer.jl/figs/cityscape.jpg is used!**
"""

# ╔═╡ e0931c2c-15e8-438d-bae4-c961e68d90ec
@bind image1file FilePicker([MIME("image/*")])

# ╔═╡ 9e2bb61a-098a-4edd-aa87-3a3484595f4d
md"""
#### Select image 2
**By default, ColorTransfer.jl/figs/sunset.jpg is used!**
"""

# ╔═╡ 3743764b-d8d3-471d-8398-e296aad2d567
@bind image2file FilePicker([MIME("image/*")])

# ╔═╡ 16ce4192-f580-46ba-80da-ac44cb13ba3b
md"""
---
"""

# ╔═╡ c6b74f81-e41a-449c-9be3-4f2dbfc34301
md"""
### Color schemes of two images
"""

# ╔═╡ ad83b6f3-98fa-4568-ae23-43ab9813a9fd
md"""
## 1. Converting images into arrays
"""

# ╔═╡ ac92d0ae-4641-4981-aab2-b63c04826119
md"""
##### 1.1. Conversion to 2D array for clustering and later calculations purposes

- ( channels x (height * width) )
"""

# ╔═╡ 2c4e983c-c922-4c2f-91e2-d5d5b2f28436
md"""
---
"""

# ╔═╡ 674c4223-7c93-4f89-bdd1-65fd51886a04
md"""
##### 1.2. Conversion to 3D array for later visualization purposes

- ( height x width x channels )
"""

# ╔═╡ 2319e25f-aae4-44aa-a548-b9994641ae4f
md"""
## 2. Clustering the images using K-means clustering

- From **clustering.jl** package, k-means clustering function **kmeans()** was used to cluster the 2D-array of images.
"""

# ╔═╡ 69addbcd-6158-4193-b4ef-b432d71912d5
md"""
---
"""

# ╔═╡ d147d490-4897-4a24-a966-5fb5de5a3347
md"""
##### 2.1. Clustered centers

- Matrix of **( channels x n_clusters )**
- Shows the cluster centers
"""

# ╔═╡ 834d0e85-ba6e-4fde-b2df-2e01188c2277
md"""
---
"""

# ╔═╡ 3b9c7acc-5a37-4f51-8f9c-d32ab4370594
md"""
##### 2.2. Counts

- Vector of **( 1 x n_clusters )**
- Shows the **size** of each cluster. (How many RGB pixels were assigned to that cluster?)
"""

# ╔═╡ 72c3d80b-e09b-4459-9216-6f9bc9669f48
md"""
---
"""

# ╔═╡ 7b865f98-a124-4c9e-884c-a6744ea7ca0d
md"""
##### 2.3. Assignments

- Vector of **( 1 x pixels )**
- Shows to which cluster each RGB pixel belongs to.
"""

# ╔═╡ 24611539-ba22-483d-8be3-b79314a67dcc
md"""
---
"""

# ╔═╡ 2ace44bb-085e-4979-b2d7-c21272df21d6
md"""
## 3. Images after the clustering

- After K-means clustering, the colors in the image look more compressed.

- Yet, the dimensions (number of pixels) are the same.

- We will transfer the color schemes of the clustered colors
"""

# ╔═╡ 4dbae5a4-1417-49c8-800c-227d37ad1f8f
md""" --- """

# ╔═╡ 4b9955f2-0900-41c7-aecc-193477f9ac7f
md"""
**Number of clusters for k-means clustering**

- Depending on the **n_cluster** value, the compression in the colors will be different.

!!! note "Different values of n_cluster"
	- For quick run of the code upon the first opening of the notebook, I set the default **n\_cluster** to 30 (decent image quality, fast run). I highly recommend you also try higher values n_cluster for a much better quality. It may take more time, but not that much!

$@bind n_cluster confirm(Slider(1:1:100; default=30, show_value=true))
"""

# ╔═╡ fc223699-6de3-460c-a116-8121bed96dfe
md"""
- Modify the Slider to a desired value, and press "Confirm" if you want to apply the new cluster value.
- (Added "confirm" button because clustering takes a few seconds.. take your time to carefully set the slider to your desired value!)
"""

# ╔═╡ ec4795e5-7c10-4b93-95a4-0a6890fc0386
md"""
---
"""

# ╔═╡ fd03fd37-2e16-40f5-a933-4991c913d420
md"""
### Original vs Clustered
"""

# ╔═╡ 90623ffc-69b5-43e1-abdf-09691c4971b3
md"""
#### Image 1
"""

# ╔═╡ 1e65fb14-93f6-43ef-8941-0e752cd213e2
md""" #### Image 2 """

# ╔═╡ 5d13c0fb-b1ca-46e5-ad09-181ff8d869b1
md"""
---
"""

# ╔═╡ 28fbebcb-2e14-4e35-8a36-097d88cc4052
md"""
## 4. Optimal transport of the clustered colors 
"""

# ╔═╡ 054ddfae-e486-4c3e-9ac4-55bb11d47daf
md"""
#### 4.1. Cost matrix calculation

- By default, **Squared euclidian distances** are calculated between cluster centers of two images.

- Below are provided a few other distance calculation. Feel free to experiment how different distance metrics affect the color transfer.
"""

# ╔═╡ cf322e23-074b-4d58-9cf1-1554bdd610eb
md"""
--- """

# ╔═╡ 54d1e2c3-ad62-4f06-9d0e-8778d0f02c16
md"""
##### 4.1.1. Distance formulas to try for cost matrix calculation
"""

# ╔═╡ 2fd226fd-0ebd-4e0f-8509-d0a788c2de73
md"""
!!! note "Only two formulas?"

	Several different formulas exist for distance calculation. However, after experimenting, these two provided the most contrasting results.
"""

# ╔═╡ df9010db-0565-43d5-b926-164d96ca400f
Sqeuclidean(x, y) = sum((x - y) .^ 2)

# ╔═╡ eaf5aa75-a3d8-4d0e-8fe1-dd250fe033c1
KLdivergence(x, y) = sum(x .* log.(x ./ y))

# ╔═╡ eb00a4c3-da73-4608-8447-5ab7d63a0876
md"""
--- """

# ╔═╡ 66a54b5a-4497-47d2-a360-0f23d6518d39
md"""
#### 4.2. Weight for each pixel

- In the course, we gave a unifrom weight for each pixel.
- But this time, we will give **different weight for each pixel.**
- Size of each cluster is normalized by **(height x weight)**, so every pixel within the same cluster will share the same weights
"""

# ╔═╡ c8a3f385-33fa-48ae-b4d1-134fffa7c22c
md"""
---
"""

# ╔═╡ 35196ba9-ac08-4583-981d-92f5d4374e52
md"""
#### 4.3. Optimal transport using the Sinkhorn algorithm

- The same algorithm from the course.
- I made sliders in the below section to play with the lambda and epsilon values.
"""

# ╔═╡ 7601994f-d7d3-4be4-91ed-a823f14f4489
md""" --- """

# ╔═╡ ecefce4d-145e-4cfe-bab5-e1a5daa6e6fd
md"""
## 5. Outcome of optimal transport on the images

- Now that we obtained the optimal distribution matrix **Pcolors**, we can map this distribution to center clusters of color schemes
"""

# ╔═╡ 24bba47e-7aa5-4463-a448-2788537faa7a
md"""
---
"""

# ╔═╡ 7c616c0e-55de-4e5f-aafb-34b85665df70
md"""
##### More and more things to experiment...

- Optional inputs in the Sinkhorn algorithm - **λ** and **ϵ** - also affect the outcome of Optimal Transport. 

- Try out the different values, see how the images below are affected.
- Change in Lambda and Epsilon are reflected instantly. Feel free to play around!
"""

# ╔═╡ 2bf1e249-821e-40d8-a391-710baae05e65
md"""
**Lambda (λ)** -> In general, increase in λ gives more vibrant colors to the image
"""

# ╔═╡ 3687fc03-af9d-4e44-9fb5-17d086822924
@bind lambda Slider(1.0:200.0, default=100, show_value=true)

# ╔═╡ 77c07e75-c6db-4106-8d04-44b619d70465
md"""
**Epsilon (ϵ)** -> Depends... it could add/reduce contrast to the images.
"""

# ╔═╡ 2901b354-1e4f-432a-a4b1-5b5e37cee104
@bind eps Slider(-4.0:1.0, default=-1, show_value=true)

# ╔═╡ 7af273d6-d725-43c6-8637-4db525f4270d
md"""
---
"""

# ╔═╡ 7f783b21-8b8e-4788-8f35-e8b644bd20ea
md"""
#### Visualization of the outcome
"""

# ╔═╡ 7a77606c-ca57-4eb7-89bf-644bb699f5fb
md"""
##### Image too dark or bright? Adjust the exposure.
"""

# ╔═╡ 4c7b5536-1583-444c-ae7f-327d96497a4a
@bind k Slider(0:0.05:2, default=1, show_value=true)

# ╔═╡ bf0e1f73-58e4-4e53-a2bf-aa009c430da6
md""" --- """

# ╔═╡ f147bad3-4dae-4f1c-b478-e5955dcf95d0
md"""
#### How about the other way around? 

- How about colors of **image1 transferred to image2?**
- This can easily be achieved by **transposing the Pcolors** distributions matrix
"""

# ╔═╡ 974e61fb-19e6-4ec3-9b6b-8e89658209f6
md"""
##### Image too dark or bright? Adjust the exposure
"""

# ╔═╡ 9d162a07-434e-4b84-a4ff-812210ec3f0e
@bind k2 Slider(0:0.05:2, default=1, show_value=true)

# ╔═╡ 5306846b-d686-47f6-bf1f-6464b85be409
md""" --- """

# ╔═╡ 52a9c486-7b05-4881-8479-f48075e58de3
md"""
### Clustered vs Transferred
"""

# ╔═╡ 2a6dd3ae-e114-4b5e-be85-67cc0b944b97
md"""
##### Image 2 colors -> Image 1
"""

# ╔═╡ e962d9cc-00a3-4e45-88c6-3b81e90d28c3
md"""
##### Image 1 colors -> Image 2
"""

# ╔═╡ f44ee7f6-b903-4b00-89ba-91b6039d3c73
md""" --- """

# ╔═╡ ddbab8c0-1440-4027-b1f4-0f083448a17e
md"""
## Appendix (source code)
"""

# ╔═╡ 8131f7cf-7027-4168-b41e-e75a4001a2a5
function load_image(x)
	"""
	A function to load an image file selected from PlutoUI.FilePicker()

	Input
		- x = selected image file from FilePicker()
	
	Return
		- loaded_file = loaded image from the selected image file path
	"""
	
	# Get the filepath
	filename = dirname(@__DIR__) * "/figs/" * x["name"]
	# Load the image from the filepath
	loaded_file = load(filename)

	# Make sure the image is in RGB colorspace.
	return RGB.(loaded_file)
end

# ╔═╡ 45264041-09d3-412c-a2ff-50c4bdc29039
# if a custom image is selected from the FilePicker above, load that image
if typeof(image1file) == Dict{Any, Any}
	image1 = load_image(image1file)
else
	# If no input from the FilePicker, we will use cityscape photo as default!
	try
		image1 = load("../figs/cityscape.jpg")
	catch
		# If local directory does not work, try online catch.
		image1url = download("https://github.com/juhlee/imagebank/blob/main/cityscape.jpg?raw=true")
		image1 = load(image1url)
	end
end

# ╔═╡ 2544a424-6730-49a5-949c-f56fb4fad413
vec(imresize(image1,8,12))

# ╔═╡ f321ac99-d7fe-40ed-9498-b56588a03270
# if a custom image is selected from the FilePicker above, load that image
if typeof(image2file) == Dict{Any, Any}
	image2 = load_image(image2file)
else
	# Else, we use sunset photography as default!
	try
		image2 = load("../figs/sunset.jpg")
	catch
		image2url = download("https://github.com/juhlee/imagebank/blob/main/sunset.jpg?raw=true")
		image2 = load(image2url)
	end
end

# ╔═╡ ff0da56a-5e85-4a61-a26c-787b0ca096f4
vec(imresize(image2,8,12))

# ╔═╡ 3038def5-3c91-4a2d-90f3-d4c827d63ce0
function image_to_2d_array(image::Matrix)
	"""
	Convert a loaded image into a 2D array of dimensions [channel x (width * height)]
	In other words: [RGB x (number of pixels in the image)]

	Input
		- image = loaded image
	
	Return
		- img_array = image converted into 2D array
	"""
	
	# Colors.jl package
	r = convert(Array{Float64}, vec(red.(image)))
	g = convert(Array{Float64}, vec(green.(image)))
	b = convert(Array{Float64}, vec(blue.(image)))

	# channelveiw() shows the array in dimensions channels x width x height.
	# For the subsequent experiment, we convert this to chaneels x (width * height)
	img_array = hcat(r,g,b)'

	return img_array
end

# ╔═╡ d3755b9c-6682-4907-ad1f-510a117eae5e
begin
	img1array = image_to_2d_array(image1)
	img2array = image_to_2d_array(image2)
end

# ╔═╡ 441e5c0f-85bf-43a3-9b34-d21fbba4dc70
begin
	im1res = kmeans(img1array, n_cluster)
	im2res = kmeans(img2array, n_cluster)
end

# ╔═╡ 00b81e4d-937b-4e00-83b8-abcbfcc7fcbe
begin
	im1_centers = im1res.centers
	im2_centers = im2res.centers
end

# ╔═╡ 6d565196-b737-44e7-ae7f-1f407bd3f6b7
begin
	im1_counts = im1res.counts
	im2_counts = im2res.counts
end

# ╔═╡ e5b7dd1c-38aa-4a2e-b8c0-92fa0c455334
begin
	h, w = size(image1)
	h2, w2 = size(image2)

	# Normalizing each cluster with height x weight.
	a_col = im1_counts / (h * w)
	b_col = im2_counts / (h2 * w2)
end

# ╔═╡ 2f84f436-d552-4923-99e6-7362945a7ef7
begin
	im1_assigns = im1res.assignments
	im2_assigns = im2res.assignments
end

# ╔═╡ b7b24b81-81a6-43e9-ac47-854f8d4c8680
function image_to_3d_array(image::Matrix)
	"""
	Convert a loaded image into a 2D array of dimensions [channel x (width * height)]
	In other words: [RGB x (number of pixels in the image)]

	Input
		- image = loaded image
	
	Return
		- img_array = image converted into 2D array
	"""

	# Colors.jl package
	img_array = channelview(image)

	# channelveiw() shows the array in dimensions channels x width x height.
	# We convert this to height x width x channels.
	img_array = permutedims(img_array, (2,3,1))

	return img_array
end

# ╔═╡ 615e0f0a-1fba-499e-b42b-3eb331311e89
begin
	img1array3D = image_to_3d_array(image1)
	img2array3D = image_to_3d_array(image2)
end

# ╔═╡ c124013f-16e5-4631-84c2-67a86ef224a2
function reassigning(img_array::Array, centers::Matrix, assignments::Vector)
	"""
	Function for assigning center cluster values back to the original image.

	Input
		- img_array   = 3D array (height x width x channel)
		- centers 	  = cluster centers of the image
		- assignments = assignments of points to clusters

	Return
		- img_new = new representation of the image
	"""

	img_new = copy(img_array)
	h, w, c = size(img_array)

	for i in 1:c # for each channel

		# Assign the center cluster to the original pixels.
		img_new[:,:,i] = reshape(centers[i,:][assignments], (h, w))
	end

	return img_new
end

# ╔═╡ a5d95227-8dbc-4323-bec8-3c66803d4034
begin
	# Reassign the center clusters to 3D array
	im1_clust = reassigning(img1array3D, im1_centers, im1_assigns)
	# Convert the array back to an image.
	im1_clust_view = colorview(RGB, permutedims(im1_clust, (3,1,2)))

	# Side-to-side comparison with the original image.
	[image1; im1_clust_view]
end

# ╔═╡ bde7b3a1-1554-43af-9108-609b286c8e37
begin
	# Same procedures from above.
	im2_clust = reassigning(img2array3D, im2_centers, im2_assigns)
	im2_clust_view = colorview(RGB, permutedims(im2_clust, (3,1,2)))

	[image2; im2_clust_view]
end

# ╔═╡ 0efb67d1-a37c-4628-a80c-b51e6437dcc7
function cost_matrix(centers1::Matrix, centers2::Matrix, f_dist)
	"""
	Function to generate a cost matrix between the two images.

	Input
		- centers1 = center clusters of image 1 (from k-means clustering)
		- cenetrs2 = center clusters of image 2 (from k-means clustering)
		- f_dist   = Distance calcuation types

	Return
		- C = the cost matrix
	"""
	# Initialize Cost matrix
	length1 = size(centers1, 2)
	length2 = size(centers2, 2)
	
	C = zeros(length1, length2)

	for i in 1:length1
		for j in 1:length2
			rgb1 = centers1[:,j]
			rgb2 = centers2[:,i]

			# Calculate the distance(differnce) between two RGB clusters.
			distance = f_dist(rgb1, rgb2)

			# Assign the distance
			C[i,j] = distance
		end
	end

	return C
end

# ╔═╡ 32c2ac0a-d0ca-4002-8c03-9f0448ac418a
begin
	# as described in the below sub-section 4.1.1.
	# you could try two formulas: Sqeuclidean and KLdivergence
	# Could've been better if PlutoUI could bind functions...
	distance_formula = Sqeuclidean
	
	# cost matrix between color schemes of two images
	C = cost_matrix(im1_centers, im2_centers, distance_formula)
end

# ╔═╡ 471b8d90-5b64-4fed-a074-47d42ed4e0e0
function transport_colors(centers1::Matrix, centers2::Matrix, P)
	"""
	With the optimal distribution matrix P, map this to the color schemes of desired image. This is the final step in this project. through this function, color schemes of image 2 will be transferred to the image 1.

	Input
		- centers1 = center clusters of image 1
		- centers2 = center clusters of image 2
		- P 	   = Optimal distribution matrix

	Return
		- centers1_new = re-mapped center clusters of image1
	"""
	centers1_new = copy(centers1)

	row, column = size(centers1_new)

	for i in 1:row
		for j in 1:column
			
			u = sum(P[:, j] .* centers2[i, :])
			v = sum(P[:, j])

			# Reassign value.. 
			centers1_new[i,j] = u / v 
		end
	end
	
	#newcent11 = permutedims(newcent11, (2,1))
	#newcent11 = reshape(newcent11, (30, 3))
	#newcent11 = permutedims(newcent11, (2,1))

	return centers1_new
end

# ╔═╡ 22a77c67-a0ed-434a-9db4-993cdce0c93b
function sinkhorn(C::Matrix, a::Vector, b::Vector; λ=1.0, ϵ=1e-8)
		n, m = size(C)
		@assert n == length(a) && m == length(b) throw(DimensionMismatch("a and b do not match"))
		@assert sum(a) ≈ sum(b) "a and b don't have equal sums"
		u, v = copy(a), copy(b)

		C_mean = sum(C) / length(C)
	
		M = exp.(-λ * (C .- C_mean))
		# normalize this matrix
		while maximum(abs.(a .- Diagonal(u) * (M * v))) > ϵ
			u .= a ./ (M * v)
			v .= b ./ (M' * u)
		  end
		return Diagonal(u) * M * Diagonal(v)
	  end

# ╔═╡ f8e6fc0f-6731-4205-a622-b30387b068a1
Pcolors = sinkhorn(C, a_col, b_col; λ=lambda, ϵ=10^(eps))

# ╔═╡ bbcb7b48-9eac-4fc6-bb34-aacab000a2d9
# Color schemes of image 2 transferred to that of image 1
im1_centers_n = transport_colors(im1_centers, im2_centers, Pcolors)

# ╔═╡ 3ab4bb47-a09c-4293-bcf0-8727287aac74
begin
	# Reassigning the cluster centers back to the original image
	im1_transf = reassigning(img1array3D, im1_centers_n, im1_assigns)
	im1_transf_view = colorview(RGB, permutedims(im1_transf, (3,1,2))) * k
end

# ╔═╡ 9b2d7059-df96-4c8d-8404-777fae5f63f7
[im1_clust_view; im1_transf_view]

# ╔═╡ a588d77e-c8b6-4bb8-b854-eed42e15cbef
im2_centers_n = transport_colors(im2_centers, im1_centers, Pcolors') # Pcolors transposed

# ╔═╡ e785cd6d-5ee6-4b31-82f9-5d0f4ed0c4f6
begin
	# Reassigning the mapped cluster centers back to the original image
	im2_transf = reassigning(img2array3D, im2_centers_n, im2_assigns)
	im2_transf_view = colorview(RGB, permutedims(im2_transf, (3,1,2))) * k2
end

# ╔═╡ 0b6c5422-7cd7-47cd-b091-6307e7ae5303
[im2_clust_view; im2_transf_view]

# ╔═╡ ec53c559-044e-4287-8b44-1123fade583c
colorscatter(colors; kwargs...) = 
	scatter(red.(colors), 
			green.(colors), 
			blue.(colors),
			xlabel="red", ylabel="green", zlabel="blue", 
			color=colors, label="",
			m = 0.5)

# ╔═╡ a6f86f24-604c-4cf5-ac46-cc7b18882277
@testset begin
	a_file_url = "https://github.com/juhlee/imagebank/blob/main/nutshell.png?raw=true"

	# Emulation of the function image_load()
	a_img = load(download(a_file_url))
	a_img = RGB.(a_img)

	# Check if the image loaded is in the RGB color space
	@test typeof(a_img) == Matrix{RGB{N0f8}}
	
	# Check if the image_to_3Darray gives a 3D array with width x height x channel
	a_array = image_to_3d_array(a_img)
	@test length(size(a_array)) == 3

	# Check if the image_to_2Darray gives a 2D array with channel x (width * height)
	a_array_2 = image_to_2d_array(a_img)
	@test length(size(a_array_2)) == 2
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Clustering = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
ImageIO = "82e4d734-157c-48bb-816b-45c225c6df19"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
Clustering = "~0.14.2"
Colors = "~0.12.8"
Distributions = "~0.25.43"
ImageIO = "~0.6.0"
Images = "~0.25.1"
PlutoUI = "~0.7.32"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "6f1d9bc1c08f9f4a8fa92e3ea3cb50153a1b40d4"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.1.0"

[[AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "ffc6588e17bcfcaa79dfa5b4f417025e755f83fc"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "4.0.1"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "d127d5e4d86c7680b20c35d40b503c74b9a39b5e"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.4"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "f9982ef575e19b0e5c7a98c6e75ee496c0f73a93"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.12.0"

[[ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "3f1f500312161f1ae067abe07d13b40f78f32e07"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.8"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "681ea870b918e7cff7111da58791d7f718067a19"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.2"

[[CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "38bcc22b6e358e88a7715ad0db446dfd3a4fea47"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.43"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "84f04fe68a3176a583b864e492578b9466d87f1e"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.6"

[[EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "d7ab55febfd0907b285fbf8dc0c73c0825d9d6aa"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.3.0"

[[FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "67551df041955cc6ee2ed098718c8fcd7fc7aebe"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.12.0"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78e2c69783c9753a91cdae88a8d432be85a2ab5e"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.0+0"

[[Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "1c5a84319923bea76fa145d49e93aa4394c73fc2"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.1"

[[Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "d727758173afef0af878b29ac364a0eca299fc6b"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.5.1"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[ImageContrastAdjustment]]
deps = ["ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "0d75cafa80cf22026cea21a8e6cf965295003edc"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.10"

[[ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "9a5c62f231e5bba35695a20988fc7cd6de7eeb5a"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.3"

[[ImageDistances]]
deps = ["Distances", "ImageCore", "ImageMorphology", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "7a20463713d239a19cbad3f6991e404aca876bda"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.15"

[[ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "15bd05c1c0d5dbb32a9a3d7e0ad2d50dd6167189"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.1"

[[ImageIO]]
deps = ["FileIO", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "816fc866edd8307a6e79a575e6585bfab8cef27f"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.0"

[[ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils", "Libdl", "Pkg", "Random"]
git-tree-sha1 = "5bc1cb62e0c5f1005868358db0692c994c3a13c6"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.1"

[[ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f025b79883f361fa1bd80ad132773161d231fd9f"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.12+2"

[[ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[ImageMorphology]]
deps = ["ImageCore", "LinearAlgebra", "Requires", "TiledIteration"]
git-tree-sha1 = "7668b123ecfd39a6ae3fc31c532b588999bdc166"
uuid = "787d08f9-d448-5407-9aad-5290dd7ab264"
version = "0.3.1"

[[ImageQualityIndexes]]
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "OffsetArrays", "Statistics"]
git-tree-sha1 = "1d2d73b14198d10f7f12bf7f8481fd4b3ff5cd61"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.0"

[[ImageSegmentation]]
deps = ["Clustering", "DataStructures", "Distances", "Graphs", "ImageCore", "ImageFiltering", "ImageMorphology", "LinearAlgebra", "MetaGraphs", "RegionTrees", "SimpleWeightedGraphs", "StaticArrays", "Statistics"]
git-tree-sha1 = "36832067ea220818d105d718527d6ed02385bf22"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.7.0"

[[ImageShow]]
deps = ["Base64", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "d0ac64c9bee0aed6fdbb2bc0e5dfa9a3a78e3acc"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.3"

[[ImageTransformations]]
deps = ["AxisAlgorithms", "ColorVectorSpace", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "42fe8de1fe1f80dab37a39d391b6301f7aeaa7b8"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.9.4"

[[Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "11d268adba1869067620659e7cdf07f5e54b6c76"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.25.1"

[[Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "00019244715621f473d399e4e1842e479a69a42e"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.2"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b15fc0a95c564ca2e0a7ae12c1f095ca848ceb31"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.5"

[[IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[JLD2]]
deps = ["DataStructures", "FileIO", "MacroTools", "Mmap", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "bcb31db46795eeb64480c89d854615bc78a13289"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.19"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "22df5b96feef82434b07327e2d3c770a9b21e023"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "e5718a00af0ab9756305a0392832c8952c7426c1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.6"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "2af69ff3c024d13bde52b34a2a7d6887d4e7b438"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.7.1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "6d105d40e30b635cfed9d52ec29cf456e27d38f8"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.12"

[[PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0b5cfbb704034b5b4c1869e36634438a047df065"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.1"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "ae6145ca68947569058866e443df69587acc1806"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.32"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[Quaternions]]
deps = ["DualNumbers", "LinearAlgebra"]
git-tree-sha1 = "adf644ef95a5e26c8774890a509a55b7791a139f"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.4.2"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays", "Statistics"]
git-tree-sha1 = "405148000e80f70b31e7732ea93288aecb1793fa"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.2.0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e6bf188613555c78062842777b116905a9f9dd49"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.0"

[[StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[Static]]
deps = ["IfElse"]
git-tree-sha1 = "b4912cd034cdf968e06ca5f943bb54b17b97793a"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.5.1"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "2884859916598f974858ff01df7dfc6c708dd895"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.3"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "d88665adc9bcf45903013af0982e2fd05ae3d0a6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "51383f2d367eb3b444c961d485c565e4c0cf4ba0"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.14"

[[StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f35e1879a71cca95f4826a14cdbf0b9e253ed918"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.15"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "991d34bbff0d9125d93ba15887d6594e8e84b305"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.5.3"

[[TiledIteration]]
deps = ["OffsetArrays"]
git-tree-sha1 = "5683455224ba92ef59db72d10690690f4a8dc297"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.3.1"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78736dab31ae7a53540a6b752efc61f77b304c5b"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.8.6+1"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─c3c61b29-ddc7-4638-9350-8ce945326d27
# ╠═03f007fe-ed84-4ee4-a806-5239843c0391
# ╟─adf59de3-bc73-4d4c-9293-47a2f8569ee5
# ╟─877f1fc5-2acd-48ad-87e3-0f28d9c9c9c7
# ╟─7d867d3b-ff9b-42dd-818d-c314a977b448
# ╟─03ad0574-699b-4046-863e-611e1a058d82
# ╟─fde7a4f2-5051-4f3a-859a-843d5d67f38e
# ╟─2aea58e2-9168-43ff-bdd0-dcd7e6ee0339
# ╟─3a9db4da-22de-4b49-9630-efc997f2e3b0
# ╠═45264041-09d3-412c-a2ff-50c4bdc29039
# ╠═f321ac99-d7fe-40ed-9498-b56588a03270
# ╟─dc7c112b-7213-4746-b86e-8cbbb8130a01
# ╟─69c0bee8-3947-4928-856d-454e5d693492
# ╟─4118339f-b3a1-4d89-8bbc-54fae475ae4c
# ╟─e0931c2c-15e8-438d-bae4-c961e68d90ec
# ╟─9e2bb61a-098a-4edd-aa87-3a3484595f4d
# ╟─3743764b-d8d3-471d-8398-e296aad2d567
# ╟─16ce4192-f580-46ba-80da-ac44cb13ba3b
# ╟─c6b74f81-e41a-449c-9be3-4f2dbfc34301
# ╟─2544a424-6730-49a5-949c-f56fb4fad413
# ╟─ff0da56a-5e85-4a61-a26c-787b0ca096f4
# ╟─ad83b6f3-98fa-4568-ae23-43ab9813a9fd
# ╟─ac92d0ae-4641-4981-aab2-b63c04826119
# ╠═d3755b9c-6682-4907-ad1f-510a117eae5e
# ╟─2c4e983c-c922-4c2f-91e2-d5d5b2f28436
# ╟─674c4223-7c93-4f89-bdd1-65fd51886a04
# ╠═615e0f0a-1fba-499e-b42b-3eb331311e89
# ╟─2319e25f-aae4-44aa-a548-b9994641ae4f
# ╠═441e5c0f-85bf-43a3-9b34-d21fbba4dc70
# ╟─69addbcd-6158-4193-b4ef-b432d71912d5
# ╟─d147d490-4897-4a24-a966-5fb5de5a3347
# ╠═00b81e4d-937b-4e00-83b8-abcbfcc7fcbe
# ╟─834d0e85-ba6e-4fde-b2df-2e01188c2277
# ╟─3b9c7acc-5a37-4f51-8f9c-d32ab4370594
# ╠═6d565196-b737-44e7-ae7f-1f407bd3f6b7
# ╟─72c3d80b-e09b-4459-9216-6f9bc9669f48
# ╟─7b865f98-a124-4c9e-884c-a6744ea7ca0d
# ╠═2f84f436-d552-4923-99e6-7362945a7ef7
# ╟─24611539-ba22-483d-8be3-b79314a67dcc
# ╟─2ace44bb-085e-4979-b2d7-c21272df21d6
# ╟─4dbae5a4-1417-49c8-800c-227d37ad1f8f
# ╟─4b9955f2-0900-41c7-aecc-193477f9ac7f
# ╟─fc223699-6de3-460c-a116-8121bed96dfe
# ╟─ec4795e5-7c10-4b93-95a4-0a6890fc0386
# ╟─fd03fd37-2e16-40f5-a933-4991c913d420
# ╟─90623ffc-69b5-43e1-abdf-09691c4971b3
# ╠═a5d95227-8dbc-4323-bec8-3c66803d4034
# ╟─1e65fb14-93f6-43ef-8941-0e752cd213e2
# ╠═bde7b3a1-1554-43af-9108-609b286c8e37
# ╟─5d13c0fb-b1ca-46e5-ad09-181ff8d869b1
# ╟─28fbebcb-2e14-4e35-8a36-097d88cc4052
# ╟─054ddfae-e486-4c3e-9ac4-55bb11d47daf
# ╠═32c2ac0a-d0ca-4002-8c03-9f0448ac418a
# ╟─cf322e23-074b-4d58-9cf1-1554bdd610eb
# ╟─54d1e2c3-ad62-4f06-9d0e-8778d0f02c16
# ╟─2fd226fd-0ebd-4e0f-8509-d0a788c2de73
# ╠═df9010db-0565-43d5-b926-164d96ca400f
# ╠═eaf5aa75-a3d8-4d0e-8fe1-dd250fe033c1
# ╟─eb00a4c3-da73-4608-8447-5ab7d63a0876
# ╟─66a54b5a-4497-47d2-a360-0f23d6518d39
# ╠═e5b7dd1c-38aa-4a2e-b8c0-92fa0c455334
# ╟─c8a3f385-33fa-48ae-b4d1-134fffa7c22c
# ╟─35196ba9-ac08-4583-981d-92f5d4374e52
# ╠═f8e6fc0f-6731-4205-a622-b30387b068a1
# ╟─7601994f-d7d3-4be4-91ed-a823f14f4489
# ╟─ecefce4d-145e-4cfe-bab5-e1a5daa6e6fd
# ╠═bbcb7b48-9eac-4fc6-bb34-aacab000a2d9
# ╟─24bba47e-7aa5-4463-a448-2788537faa7a
# ╟─7c616c0e-55de-4e5f-aafb-34b85665df70
# ╟─2bf1e249-821e-40d8-a391-710baae05e65
# ╟─3687fc03-af9d-4e44-9fb5-17d086822924
# ╟─77c07e75-c6db-4106-8d04-44b619d70465
# ╟─2901b354-1e4f-432a-a4b1-5b5e37cee104
# ╟─7af273d6-d725-43c6-8637-4db525f4270d
# ╟─7f783b21-8b8e-4788-8f35-e8b644bd20ea
# ╟─7a77606c-ca57-4eb7-89bf-644bb699f5fb
# ╟─4c7b5536-1583-444c-ae7f-327d96497a4a
# ╠═3ab4bb47-a09c-4293-bcf0-8727287aac74
# ╟─bf0e1f73-58e4-4e53-a2bf-aa009c430da6
# ╟─f147bad3-4dae-4f1c-b478-e5955dcf95d0
# ╠═a588d77e-c8b6-4bb8-b854-eed42e15cbef
# ╟─974e61fb-19e6-4ec3-9b6b-8e89658209f6
# ╟─9d162a07-434e-4b84-a4ff-812210ec3f0e
# ╠═e785cd6d-5ee6-4b31-82f9-5d0f4ed0c4f6
# ╟─5306846b-d686-47f6-bf1f-6464b85be409
# ╟─52a9c486-7b05-4881-8479-f48075e58de3
# ╟─2a6dd3ae-e114-4b5e-be85-67cc0b944b97
# ╟─9b2d7059-df96-4c8d-8404-777fae5f63f7
# ╟─e962d9cc-00a3-4e45-88c6-3b81e90d28c3
# ╟─0b6c5422-7cd7-47cd-b091-6307e7ae5303
# ╟─f44ee7f6-b903-4b00-89ba-91b6039d3c73
# ╟─ddbab8c0-1440-4027-b1f4-0f083448a17e
# ╠═8131f7cf-7027-4168-b41e-e75a4001a2a5
# ╠═3038def5-3c91-4a2d-90f3-d4c827d63ce0
# ╠═b7b24b81-81a6-43e9-ac47-854f8d4c8680
# ╠═c124013f-16e5-4631-84c2-67a86ef224a2
# ╠═0efb67d1-a37c-4628-a80c-b51e6437dcc7
# ╠═471b8d90-5b64-4fed-a074-47d42ed4e0e0
# ╠═22a77c67-a0ed-434a-9db4-993cdce0c93b
# ╠═ec53c559-044e-4287-8b44-1123fade583c
# ╟─a6f86f24-604c-4cf5-ac46-cc7b18882277
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
