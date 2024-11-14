%  Script for extracting the boundary layer of a flow around a cylinder.

clear; close all; clc

function [bl_upper, bl_lower] = extract_BL(mesh, V_inf)
    %   Extract the boundaray layer of the flow by iterating on the face of
    % the mesh.

    arguments (Input)
        mesh   (1,1) MeshReader.Mesh
        V_inf  (1,1) double
    end

    % Initialization:
    % ---------------
    bl_upper = MeshReader.MeshLine();
    bl_lower = MeshReader.MeshLine();
    fprintf("\nLooking for boundray layer in %s\n", mesh.name)

    % Iterate on the mesh:
    % --------------------
    utils.progressBar(0,mesh.nb_faces,"init",true)
    for ii = 1:1:mesh.nb_faces

        % Extract face data:
        % ------------------
        face_data = mesh.face_data(ii);

        % Check if CL in this face:
        % -------------------------
        %   For a face contain the CL, it must have at least
        % one node with a x-velocity > 0.99*Vinf and at least
        % one node with a x-velocity < 0.99*V_inf.
        %   If one node have a x-velocity with the value of 
        % 0.99*V_inf, then the CL is on this node.
        if max(face_data.("x-velocity")) < 0.99*V_inf || min(face_data.("x-velocity")) > 0.99*V_inf
            utils.progressBar(ii,mesh.nb_faces)
            continue
        end

        % Append Node Data to the CL:
        % ---------------------------

        % CL is on a node of the face
        if any(face_data.("x-velocity") == 0.99*V_inf)

            idx = face_data.nodenumber(face_data.("x-velocity") == 0.99*V_inf);

            for jj = 1:1:numel(idx)
                new_node = mesh.node(idx(jj));
                if new_node.y_coord <= 0
                    bl_lower.addNode(new_node);
                end
                if new_node.y_coord >= 0
                    bl_upper.addNode(new_node);
                end
            end

        % CL is in the face
        else
            new_face = mesh.face(ii);
            new_node = new_face.findNode("u_x",0.99*V_inf);

            for jj = 1:1:numel(new_node)
                if new_node(jj).y_coord <= 0
                    bl_lower.addNode(new_node(jj));
                end
                if new_node(jj).y_coord >= 0
                    bl_upper.addNode(new_node(jj));
                end
            end

        end

        utils.progressBar(ii,mesh.nb_faces)
    end % Iterate on the mesh
    
    % Re-ordone the lines:
    % --------------------
    bl_upper.sort("x_coord");
    bl_lower.sort("x_coord");

    fprintf("\n\n%d nodes on BL found in the mesh:\n", bl_lower.n_point+bl_upper.n_point)
    fprintf("\t- %d for the upper BL\n",bl_upper.n_point)
    fprintf("\t- %d for the lower BL\n",bl_lower.n_point)

end
function [cyl_upper, cyl_lower] = extract_cylinderWall(mesh)
    % Extract the nodes where the velocity magnitude is null.

    % Initialization:
    % ---------------
    cyl_upper = MeshReader.MeshLine();
    cyl_lower = MeshReader.MeshLine();
    fprintf("\nLooking for cylinder wall in %s\n", mesh.name)

    % Iterate on the mesh:
    % --------------------
    utils.progressBar(0,mesh.nb_nodes,"init",true)
    for ii = 1:1:mesh.nb_nodes

        if mesh.node_data(ii).("velocity-magnitude") > 1e-12
            utils.progressBar(ii,mesh.nb_nodes)
            continue
        end

        new_node = mesh.node(ii);
        if new_node.y_coord >= 0
            cyl_upper.addNode(new_node);
        end
        if new_node.y_coord <= 0
            cyl_lower.addNode(new_node);
        end

        utils.progressBar(ii,mesh.nb_nodes)
    end

    % Re-ordone the lines:
    % --------------------
    cyl_upper.sort("x_coord");
    cyl_lower.sort("x_coord");

    fprintf("\n\n%d nodes on cylinder wall found in the mesh:\n", cyl_lower.n_point+cyl_upper.n_point)
    fprintf("\t- %d for the upper cylinder wall\n",cyl_upper.n_point)
    fprintf("\t- %d for the lower cylinder wall\n",cyl_lower.n_point) 
end






%% Main Process
%% ============

import MeshReader.*
import utils.progressBar

% Initialisation:
% ---------------
V_inf = 200; % m.s^(-1)
mesh = Mesh("Demo/data/Case1");
[BL_upper, BL_lower] = extract_BL(mesh, V_inf);
[CYL_upper,CYL_lower] = extract_cylinderWall(mesh);

% Plot boundary layer:
% --------------------

% Cartesian
ax_C = axes(figure());
hold(ax_C,'on'),grid(ax_C,'on')
plot(ax_C,[BL_upper.nodes.x_coord],[BL_upper.nodes.y_coord],"Color","#0072BD")
plot(ax_C,[BL_lower.nodes.x_coord],[BL_lower.nodes.y_coord],"Color","#77AC30")
plot(ax_C,[CYL_upper.nodes.x_coord],[CYL_upper.nodes.y_coord],"Color","#A2142F")
plot(ax_C,[CYL_lower.nodes.x_coord],[CYL_lower.nodes.y_coord],"Color","#A2142F")
xlim(ax_C, [mesh.min("x-coordinate"),mesh.max("x-coordinate")]); xlabel(ax_C, "x (m)")
ylim(ax_C, [mesh.min("y-coordinate"),mesh.max("y-coordinate")]); ylabel(ax_C, "y (m)")
legend(ax_C,{'BL-upper','BL-lower','Cylinder wall'})
title(ax_C,"Boundary Layer in cartesian coordinate")

% Polar
ax_P = axes(figure());
hold(ax_P,'on'),grid(ax_P,'on')
plot(ax_P,180-rad2deg([BL_upper.nodes.t_coord]),[BL_upper.nodes.r_coord]-2,"Color","#0072BD")
plot(ax_P,180-rad2deg(abs([BL_lower.nodes.t_coord])),[BL_lower.nodes.r_coord]-2,"Color","#77AC30")
plot(ax_P,180-rad2deg([CYL_upper.nodes.t_coord]),[CYL_upper.nodes.r_coord]-2,"Color","#A2142F")
plot(ax_P,180-rad2deg(abs([CYL_lower.nodes.t_coord])),[CYL_lower.nodes.r_coord]-2,"Color","#A2142F")
xlabel(ax_P,"\theta (°)","Interpreter","tex"); ylabel(ax_P,"Distance to cylinder wall (m)")
legend(ax_P,{'BL-upper','BL-lower','Cylinder wall'})
title(ax_P,"Boundary Layer in polar coordinate")