%  Script for extracting the velocity profil of a flow around a cylinder.

clear; close all; clc

function lines_coordinates = polar2cartesian(Theta,R)
    lines_coordinates = zeros(numel(Theta),numel(R),2,"double");
    for tt = 1:1:numel(Theta)
        lines_coordinates(tt,:,1) = R.*cos(Theta(tt));
        lines_coordinates(tt,:,2) = R.*sin(Theta(tt));
    end
end
function profils = extractProfiles(mesh,theta,r,options)
    % Extract the velocity profiles around the cylinder.

    arguments (Input)
        mesh  (1,1) MeshReader.Mesh
        theta (1,:) double {mustBeNonempty(theta)}
        r     (1,:) double {mustBeNonempty(r)}

        options.nb_points  (1,1) double {mustBeGreaterThan(options.nb_points,1),mustBeInteger(options.nb_points)} = 150
        options.angle_unit (1,1) string {mustBeMember(options.angle_unit,["degree","radian"])} = "degree"
    end

    % Get coordinates:
    % ----------------
    if isscalar(r) % numel(r) == 1
        r = [0,r];
    elseif numel(r) > 2
        error("Too many elements in 'r', it must be in the form [r_min,r_max] or [r_max]")
    end
    R = r(1) : (r(2)-r(1))/(options.nb_points-1) : r(2);
    if strcmp(options.angle_unit,"degree")
        theta = deg2rad(theta);
    end
    lines_coordinates = polar2cartesian(theta,R);
    coord_min = min(lines_coordinates,[],[1,2]); coord_min = [coord_min(1,1,1),coord_min(1,1,2)];
    coord_max = max(lines_coordinates,[],[1,2]); coord_max = [coord_max(1,1,1),coord_max(1,1,2)];
    fprintf("\nLooking for %d lines of %d points in %s -\n",numel(theta),numel(R),mesh.name)

    % Iterate on the mesh:
    % --------------------
    lines_faces = repmat(MeshReader.MeshFace, numel(theta),numel(R));
    utils.progressBar(0,mesh.nb_faces,"title","Searching for faces","init",true)
    for ii = 1:1:mesh.nb_faces

        % Pre-selection:
        % --------------
        if coord_min(1) > max(mesh.face_data(ii).("x-coordinate")) || coord_max(1) < min(mesh.face_data(ii).("x-coordinate"))
            utils.progressBar(ii,mesh.nb_faces,"title","Searching for faces")
            continue
        elseif coord_min(2) > max(mesh.face_data(ii).("y-coordinate")) || coord_max(2) < min(mesh.face_data(ii).("y-coordinate"))
            utils.progressBar(ii,mesh.nb_faces,"title","Searching for faces")
            continue
        end

        % Get faces containing the nodes:
        % -------------------------------
        face = mesh.face(ii);
        for jj = 1:1:numel(theta)
            for kk = 1:1:numel(R)
                if face.contain(lines_coordinates(jj,kk,1),lines_coordinates(jj,kk,2))
                    lines_faces(jj,kk) = face;
                end
            end
        end
        utils.progressBar(ii,mesh.nb_faces,"title","Searching for faces")
        
    end

    % Extrapole nodes:
    % ----------------
    profils = repmat(MeshReader.MeshLine,numel(theta),1);
    tot = numel(theta)*numel(R);
    fprintf("\n");utils.progressBar(0,tot,"title","Searching for nodes","init",true)
    for ii = 1:1:numel(theta)
        % Create new line because repmat copy a handle
        profils(ii) = MeshReader.MeshLine(numel(R));
        for jj = 1:1:numel(R)
            profils(ii,1).addNode( ...
                lines_faces(ii,jj).interpolate( ...
                    lines_coordinates(ii,jj,1), lines_coordinates(ii,jj,2) ...
                    ) ...
                );
            act = (ii-1)*numel(R) + jj;
            utils.progressBar(act,tot,"title","Searching for nodes")
        end
    end
    fprintf("\n")
    
end



%% Main Process:
%% =============

import MeshReader.*
import utils.progressBar

% Initialization:
% ---------------
V_inf = 200;              % m.s^(-1)
theta = [90,70,50,30,10]; % degree
mesh = MeshReader.Mesh("Demo/data/Case2");
PV = extractProfiles(mesh,theta,[2,3],"nb_points",500);

% Plot:
% -----
ax = axes(figure());
hold(ax,'on'), grid(ax,'on')
legend_txt = cell(numel(theta),1);
for ii = 1:1:numel(theta)

    PV(ii).sort("r_coord");
    plot(ax,[PV(ii).nodes.u_x],[PV(ii).nodes.r_coord])
    legend_txt{ii} = sprintf("\\theta = %d°",theta(ii));
    
end
xline(ax,0.99*V_inf,"HandleVisibility","off","Visible","on","Label","0.99\timesV_{inf}","Interpreter","tex")
xlabel(ax,"x-velocity (m.s^{-1})",'Interpreter','tex')
ylabel(ax,"r (m)")
title_txt = "Velocity Profile for \\theta = " + join(repmat("%d",numel(theta),1),'°, ') + "°";
title(ax,sprintf(title_txt, theta),"Interpreter","tex")
legend(ax,legend_txt)
