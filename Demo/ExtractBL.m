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
                    bl_lower = bl_lower.addNode(new_node);
                end
                if new_node.y_coord >= 0
                    bl_upper = bl_upper.addNode(new_node);
                end
            end

        % CL is in the face
        else
            new_face = mesh.face(ii);
            new_node = new_face.findNode("u_x",0.99*V_inf);

            for jj = 1:1:numel(new_node)
                if new_node(jj).y_coord <= 0
                    bl_lower = bl_lower.addNode(new_node(jj));
                end
                if new_node(jj).y_coord >= 0
                    bl_upper = bl_upper.addNode(new_node(jj));
                end
            end

        end

        utils.progressBar(ii,mesh.nb_faces)
    end % Iterate on the mesh

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
            cyl_upper = cyl_upper.addNode(new_node);
        end
        if new_node.y_coord <= 0
            cyl_lower = cyl_lower.addNode(new_node);
        end

        utils.progressBar(ii,mesh.nb_nodes)
    end

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
mesh = Mesh("Demo/data/Case2");
[BL_upper, BL_lower] = extract_BL(mesh, V_inf);
[CYL_upper,CYL_lower] = extract_cylinderWall(mesh);


% Sort BL nodes by 'nearestNeighbourt':
% -------------------------------------
fprintf("\nStarting to sort the boundary layer:\n")
fprintf("\t- Upper layer (%d nodes) - ",BL_upper.n_point)
BLdata_upper = BL_upper.sort(["x_coord","y_coord","t_coord","r_coord"],"order","nearestNeighbour");
fprintf("done !\n\t- Lower layer (%d nodes) - ",BL_lower.n_point)
BLdata_lower = BL_lower.sort(["x_coord","y_coord","t_coord","r_coord"],"order","nearestNeighbour");
fprintf("done !\n")


% Plot boundary layer:
% --------------------

% Cartesian
ax_C = axes(figure());
hold(ax_C,'on'),grid(ax_C,'on')
plot(ax_C,BLdata_upper(:,1),BLdata_upper(:,2),"Color","#0072BD")
plot(ax_C,BLdata_lower(:,1),BLdata_lower(:,2),"Color","#77AC30")
plot(ax_C,CYL_upper.sort("x_coord"),CYL_upper.sort("y_coord","from","x_coord"),"Color","#A2142F")
plot(ax_C,CYL_lower.sort("x_coord"),CYL_lower.sort("y_coord","from","x_coord"),"Color","#A2142F")
axis(ax_C,"equal")
legend(ax_C,{'BL-upper','BL-lower','Cylinder wall'})
title(ax_C,"Boundary Layer in cartesian coordinate")


% Polar
ax_P = axes(figure());
hold(ax_P,'on'),grid(ax_P,'on')
plot(ax_P,180-rad2deg(BLdata_upper(:,3)),BLdata_upper(:,4)-2,"Color","#0072BD")
plot(ax_P,180-rad2deg(abs(BLdata_lower(:,3))),BLdata_lower(:,4)-2,"Color","#77AC30")
plot(ax_P,180-rad2deg(CYL_upper.sort("t_coord","from","x_coord")),CYL_upper.sort("r_coord","from","x_coord")-2,"Color","#A2142F")
plot(ax_P,180-rad2deg(abs(CYL_lower.sort("t_coord","from","x_coord"))),CYL_lower.sort("r_coord","from","x_coord")-2,"Color","#A2142F")
xlabel(ax_P,"\theta (°)","Interpreter","tex"); ylabel(ax_P,"Distance to cylinder wall (m)")
legend(ax_P,{'BL-upper','BL-lower','Cylinder wall'})
title(ax_P,"Boundary Layer in polar coordinate")