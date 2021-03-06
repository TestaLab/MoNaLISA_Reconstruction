function [corrected] = Skew_stripe_corr( skew_fac, line_px, im, lines_per_square, rot)
%Corrects image for stripe and skew artifact.
%rot indicates if the image (thus subsquares) should be rotated before
%correction (depends on scan rotation)
    if rot
        im = rot90(im);
    end
    imsize_x = size(im, 2);
    imsize_y = size(im, 1);
    % Skew correction
    
    [yi, xi] = ndgrid(0:imsize_y-1, 0:imsize_x-1);
    rel_pos_in_square = xi./lines_per_square - floor(xi./lines_per_square);

    y_shift = skew_fac * rel_pos_in_square * lines_per_square;
    
    
    
    yi_shifted = 1 + yi - y_shift;
    xi = 1 + xi;
    skew_corrected = interp2(im, xi, yi_shifted, 'cubic');  
    skew_corrected(isnan(skew_corrected)) = 0;
    
    
    x_coords = 1:imsize_x;

    x_coords = mod(x_coords, lines_per_square);
    selection_bool = mod(x_coords, 2) == 0;
    selection = skew_corrected(:, selection_bool);
        
    size_selection_y = size(selection, 1);
    size_selection_x = size(selection, 2);
    [yi xi] = ndgrid(1:size_selection_y, 1:size_selection_x);

    yi_shifted = yi + line_px;

    shifted_selection = interp2(selection, xi, yi_shifted);
    shifted_selection(isnan(shifted_selection)) = min(im(:));
    shifted_im = skew_corrected;
    shifted_im(:,selection_bool) = shifted_selection;
    corrected = shifted_im;
    if rot
        corrected = rot90(corrected, 3);
    end

end

