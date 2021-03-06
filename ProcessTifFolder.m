%% Load all images in the folder, convert to RGB


baseDir = '/bigstore/GeneralStorage/Alon/JuliesAnts' %parent directory where all the movies are
myFolder = uigetdir(baseDir);

if ~isdir(myFolder)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
    uiwait(warndlg(errorMessage));
    return;
end
%find all *.tif files
filePattern = fullfile(myFolder, '*.tif');
tifFiles = dir(filePattern);

%make placeholder
stack = cell(numel(tifFiles),1);

%load and convert all images
for k = 1:length(tifFiles)
    baseFileName = tifFiles(k).name;
    fullFileName = fullfile(myFolder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    imageArray = mosaicToRGB(single(imread(fullFileName))/2^16);
    stack{k} = imageArray;
end
stack = cat(4,stack{:});

%% Look at the first timeframe. Create masks for the different wells

im = squeeze(stack(:,:,:,1));


hFig = figure(332);
hFig.NumberTitle = 'off';
hFig.Name = 'How many wells'
imagesc(im); shg
prompt = 'How many wells? ';
nWells = str2double(inputdlg(prompt));

%BW will be a mask (1 inside the wells, 0 outside)
BW = zeros(size(im,1), size(im,2));

for i=1:nWells
    hFig.Name = ['Mask well ' num2str(i) ' of ' num2str(nWells)]
    if i==1
        [bw1, el] = roicirclecrop(im);
        
    else
        [bw1, el] = roicirclecrop(bsxfun(@times, im,~BW),'Position', el.getPosition);
    end
    BW = BW + bw1;
    BW = BW>0;
end
imagesc(bsxfun(@times, im,~BW))



%% Find threshold for what is considered "food"
%im is now an RGB image, the green channel is saturated, the blue channel
%has reflections from the light source. The red channels is ok. Ideally
%there should be some hardware fixes for this in the future.
im = squeeze(stack(:,:,:,1));
I = im(:,:,1); %red channel

hFig = figure(332);
hFig.NumberTitle = 'off';
hFig.Name = 'Select region inside the wells with NO ants'

imagesc(I)
axialROI=impoly;
axialROImask=createMask(axialROI);

%taking anything above mean+3std in the red channel as food
threshFood = mean(I(axialROImask))+3*std(I(axialROImask));
imshowpair(im(:,:,1), I.*(I>threshFood));
hFig.Name = 'White is food'

%taking anything below mean-3std in the red channel as Ants
hFig2 = figure(333);
hFig2.NumberTitle = 'off';

threshAmIAnt = mean(I(axialROImask))-3*std(I(axialROImask));
imshowpair(I, ((I.*BW)<threshAmIAnt-(~BW)));
hFig2.Name = 'Purple is Ants'
%% Now process whole stack
totalFood = squeeze(sum(sum((stack(:,:,1,:)-median(I(axialROImask))).*(stack(:,:,1,:)>threshFood))));
totalAnts = squeeze(sum(sum(bsxfun(@minus, bsxfun(@times, squeeze(stack(:,:,1,:)), BW)<threshAmIAnt,~BW))));


%% Plot results
set(0,'DefaultTextInterpreter', 'tex')
set(0, 'DefaultAxesFontName', 'Arial')
set(0, 'DefaultAxesFontSize', 20)
set(0, 'DefaultUIControlFontName', 'Arial')
set(0,'defaulttextfontname','Arial');
set(0,'defaulttextfontsize',22);
set(groot,'defaultFigureColor','w')
set(groot,'defaultAxesColor','w')
set(groot,'DefaultLineMarkerSize',3)
set(groot,'defaultAxesTickLength',[0.03 0.01])
set(groot,'defaultLineLineWidth',2)

yyaxis left
plot(1:length(totalFood), totalFood)
ylabel('total Food(a.u.)')
yyaxis right
plot(1:length(totalFood), totalAnts); shg
xlabel('time(frames)')
ylabel('total Ants(a.u.)')

