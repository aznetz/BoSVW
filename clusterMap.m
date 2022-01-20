function clusterMap(Image, clust_idx, Mask, patient_idx, Nth, overlap, lineWidth, visual)
% modified 2/28/21
% plot all clustering on the original image
% Image: 'cell' contains images
% Author: Joonsang Lee

if nargin == 3, overlap = 0; visual = 1; Nth=1; end

size_patch = 256;
move_patch = size_patch - overlap;
rtSize = 256 - 16; % can be change to 128-16
%colorIdx  = {'b','g','r','y','c','w','k', [0 0.6 0.8], [0.85 0.3 0.1]};
%colorIdx = {'r','g','b','c',[0 0.6 0.8],[0.8 0.3 0.1],'y', 'w', 'k','m'};
colorIdx  = {'r','b','g','k','c',[0.85 0.3 0.1],'y', [0 0.6 0.8], 'w'};

if ~isa(Image, 'cell')
    IMG{1} = Image;
else
    IMG = Image;
end

N = sum(patient_idx(1:Nth)) - patient_idx(Nth); % N: from 1 to (N_th - 1) 
k=0;
for n=1:size(IMG,1)
    I = IMG{n};
    [row, col, ch] = size(I);
    if n == visual || visual == 999 % 999: all plot
        figure, imshow(I)
        set(gcf, 'color', 'w')
        %title(sprintf('Image %02d', n))
        
        for i = 1:floor(row/move_patch) - 1
            for j = 1:floor(col/move_patch) - 1
                r1 = move_patch*(i-1)+1; r2 = move_patch*(i-1)+ size_patch;
                c1 = move_patch*(j-1)+1; c2 = move_patch*(j-1)+ size_patch;
                if Mask(i,j) == 1
                    k = k + 1;
                    rectangle('Position', [c1, r1, rtSize, rtSize], 'EdgeColor',colorIdx{clust_idx(N+k)}, 'LineWidth', lineWidth)
                    
%                     if clust_idx(N+k) == 3
%                         rectangle('Position', [c1, r1, rtSize, rtSize], 'EdgeColor',colorIdx{clust_idx(N+k)}, 'LineWidth', 3)
%                     end
                end
            end
        end
    end
end

