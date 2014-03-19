%the demo program calculates avg faces for the 10 subdirectories under
%./image/, and display them on a single figure
for i = 1:10
    imgdir = strcat('./images/', num2str(i));
	im = AverageFace(imgdir);
	subplot(2,5,i),imshow(im);
end