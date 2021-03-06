classdef Image < dynamicprops
    % A class representing an arbitrary (rectangular) Image. This class plays mostly an organisational role by allowing
    % the user to keep data related to an image in a compact way.    
    % (c) Achlioptas, Corman, Guibas  - 2015  -  http://www.fmaplib.org
    
    % TODO: size(), remove option of reporting size of collection (see dependencies)
    %       delete set_patches()
    %
    properties (GetAccess = public, SetAccess = private)
        % Basic properties that every instance of the Image class has.        
        CData        %   (height x width) or (height x width x 3) matrix capturing the image's color data.
        height       %   (int)     -    Number of vertical pixels.
        width        %   (int)     -    Number of horizontal pixels.
        name         %   (String)  -    (default = '') A string identifying the image, e.g., 'Mandrill'.
    end
    
    methods (Access = public)               
        function obj = Image(varargin)
            % Class Constructor.
            % Input:
            %       First argument:
            %           Case 1. Filepath (string) of an image, which will be opened by imread.
            %           Case 2. 2D or 3D Matrix containing the image's color data.
            %
            %       Second argument:
            %           (optional, string) describing the name of the image.
            if nargin == 0
                obj.CData = [];
            elseif ischar(varargin{1})
                obj.CData = imread(varargin{1});
            else % Directly provide the matrix with the pixel conntent.
                if size(varargin{1}, 1) < 1 || size(varargin{1}, 2) < 1
                    error('Image constructor: stores image matrices and expects at least a 2D matrix as input.')
                end
                obj.CData = varargin{1};                
            end
            [obj.height, obj.width, ~] = size(obj.CData);
            if nargin > 1 && ischar(varargin{end}) % Add potential name of picture.
                obj.name = varargin{end};
            else
                obj.name = '';
            end                           
        end
        
        function [varargout] = size(self)
            if length(self) > 1 % Case: Array of Image objects.
                varargout{1} = length(self);               
                return
            end
            
            if isempty(self.CData) % Empty image.
                varargout{1}  = 0;
                return
            end
            
            % Non empty Single Image: return height, width.
            if nargout == 2    
                varargout = cell(nargout);
                varargout{1} = self.height;
                varargout{2} = self.width;
            else
                varargout{1} = [self.height, self.width];
            end
        end
        
        function [h] = plot(obj)
            % Plots the image and returns the graphic's handle to it.            
            h = imshow(obj.CData);
            if ~ isempty(obj.name)
                title_text = strrep(obj.name, '_', '\_'); % Bypass tex interpreter.
                title(['Image name = ' title_text]);
            end
        end
        
        function c = color(obj)
            % Returns every pixel with its content (i.e., color).
            if isa(obj.CData, 'uint8') || isa(obj.CData, 'uint16')
                c = im2double(obj.CData);                  % Makes each chanel have values in [0,1].
            else 
                c = obj.CData;    % TODO-P See what other data types are expected on an image.
            end
        end
           
        function a = area(obj)                       
            a = obj.height * obj.width;
        end
        
        function [b] = is_rgb(obj)
            b = ndims(obj.CData) == 3;
        end
        
        function obj = im2single(obj)
            obj.CData = im2single(obj.CData);
        end
                                                        
        function [new_im] = resize(obj, new_height, new_width)
            imres = imresize(obj.CData , [new_height, new_width], 'bilinear');
            new_im = Image(imres, [obj.name '-resized']);
        end
                
        function c = apply_mask(self, mask)
            % Applies 2-dimensional mask in every channel of the image.
            c = self.color();
            c(:,:,1) = c(:,:,1) .* mask;
            c(:,:,2) = c(:,:,2) .* mask;
            if self.is_rgb()
                c(:,:,3) = c(:,:,3) .* mask;
            end
        end
        
                
        %
        % Not necessary property
        %
        function set_resized_image(obj, new_height, new_width)            
            propname = 'resized';            
            if ~ isprop(obj, propname)
                obj.addprop(propname);            
            end
            obj.(propname) = obj.resize(new_height, new_width);
        end
        
        function [resized] = get_resized_image(obj)
            resized = obj.resized;
        end
        
        function [obj] = set_gt_segmentation(obj, segmentation)
            % Adds dynamic property 'gt_segmentation' corresponding to a groundtruth segmentation of the image.
            propname = 'gt_segmentation';
            if isprop(obj, propname)
                obj.(propname) = segmentation;
            else
                obj.addprop(propname);
                obj.(propname) = segmentation;
            end
        end
        
        %
        % Methods regarding Patches (can be moved)
        % 
        function [F] = content_in_patch(obj, patch)
            [xmin, ymin, xmax, ymax] = patch.get_corners();            
            F = obj.CData(ymin:ymax, xmin:xmax, :);
        end
                
        function [h] = plot_patch(obj, patch)
            h = obj.plot();
            hold on;
            [xmin, ymin, xmax, ymax] = patch.get_corners();            
            plot([xmin xmax xmax xmin xmin],[ymin ymin ymax ymax ymin], 'Color', 'r', 'LineWidth', 2);
        end
                       
        function obj = set_patches(obj, patches)
            propname = 'patches';
            if isprop(obj, propname)
                warning('Updating image to a new set of patches.');                
            else
                obj.addprop(propname);
            end            
            obj.(propname) = Patch_Collection(patches, obj);
        end

    end % End of (public) instance methods.
    
    methods (Static)
        function I = white_image(h, w)
            I = Image(ones(h, w, 3), 'black_image');
        end    
        
%         function I = tile_image(h, w)
%             c = zeros(h, w, 3);
%             c(w/2:
%             
%             I = Image(zeros(h, w, 3), 'tile_image');
% 
%         end    
        
        function new_values = normalize_pixel_values(values)
            if ndims(values) < 3   % Grayscale image or vector.
                new_values = values - min(min(values));
                new_values = new_values ./ max(max(new_values));
            else
                error('Not implemented yet.')
            end         
        end
    end
    
end