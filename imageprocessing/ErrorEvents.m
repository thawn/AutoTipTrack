classdef ErrorEvents < handle
  properties
    touching_border = 0;
    cluster_cod_low = 0;
    endpoint_cod_low = 0;
    middlepoint_cod_low = 0;
    bead_cod_low = 0;
    fil_cod_low = 0;
    degenerated_fil = 0;
    empty_object = 0;
    point_not_fitted = 0;
    found_wrong_type = 0;
    object_too_dark = 0;
    fit_hit_bounds = 0;
    fit_impossible = 0;
    area_too_small = 0 ;
    abort = 0;
  end
end