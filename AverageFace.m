function [ avgface ] = AverageFace( imgdir )

    %face++ credentials
    API_KEY = 'd45344602f6ffd77baeab05b99fb7730';
    API_SECRET = 'jKb9XJ_GQ5cKs0QOk6Cj1HordHFBWrgL';
    api = facepp(API_KEY, API_SECRET);
    
    %get filenames
    files = dir(imgdir);
    %eliminate . and ..
    files = files(3:length(files));
    filenames = extractfield(files,'name');
    
    %init vars
    ims = cell(length(filenames),1);
    landmarksx = [];
    landmarksy = [];
    numFaces = 0;
    
    %face++ landmark detect
    for i = 1: length(filenames)
        filenames(i) = fullfile(imgdir,filenames(i));
        disp(strcat('Detecting landmark: ',filenames{i}));
        im = imread(filenames{i});
        ims{i} = im;
        
        %face detect
        rst1 = detect_file(api, filenames{i}, 'pose');
        num = length(rst1{1}.face);
        if (num ~= 1)
            continue;
        end
        numFaces = numFaces + 1;
        img_width = rst1{1}.img_width;
        img_height = rst1{1}.img_height;
        face = rst1{1}.face{1};
        %landmark detect
        ret = api.landmark(face.face_id, '83p');
        landmark_points = ret{1}.result{1}.landmark;
        if i == 1
            landmark_names = fieldnames(landmark_points);
        end
        
        landmark.x = zeros(length(landmark_names) + 8, 1);
        landmark.y = zeros(length(landmark_names) + 8, 1);
        
        %manually add edge reference points for DT
        landmark.x(1) = 0;
        landmark.y(1) = 0;
        landmark.x(2) = img_width/2;
        landmark.y(2) = 0;
        landmark.x(3) = img_width;
        landmark.y(3) = 0;
        landmark.x(4) = 0;
        landmark.y(4) = img_height/2;
        landmark.x(5) = 0;
        landmark.y(5) = img_height;
        landmark.x(6) = img_width;
        landmark.y(6) = img_height/2;
        landmark.x(7) = img_width/2;
        landmark.y(7) = img_height;
        landmark.x(8) = img_width;
        landmark.y(8) = img_height;
        
        %append face++ detected landmarks
        for j = 9 : (length(landmark_names)+8)
            pt = getfield(landmark_points, landmark_names{j-8});
            landmark.x(j) = pt.x * img_width / 100;
            landmark.y(j) = pt.y * img_height / 100;
        end
        landmarksx = [landmarksx landmark.x];
        landmarksy = [landmarksy landmark.y];
    end
    disp('Face & landmarks detected');
    
    %calculate the standard landmark location by simple averaging
    stdLandmark = [mean(landmarksx,2), mean(landmarksy,2)];
    
    %piecewise affine transform for all imgs, then blend them together
    avgface = zeros(img_height, img_width, 3, 'uint32');
    count = 0;
    for i = 1:numFaces
        landmarki = [landmarksx(:,i), landmarksy(:,i)];
        %try catch to prevent fold-over triangles
        try
            t_concord = cp2tform(landmarki, stdLandmark, 'piecewise linear');
            im = imtransform(ims{i},t_concord,'XData',[1 img_width], 'YData',[1 img_height]);
            im = uint32(im);
            avgface = avgface + im;
            count = count + 1;
        catch ex
            disp(ex);
        end
    end
    
    %divide by count to get avg
    avgface = avgface/count;
    avgface = uint8(avgface);
    %imshow(avgface);
end

