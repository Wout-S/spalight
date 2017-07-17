function showGeom(no,el,nopr)
    
    %to do:
    %return handles (optionally) to user?
    %plot applied moments
    %take force and moment vectors into account for deciding tag placement
    %process special nodes
    %(z-index visibility thing for annotations)

    %do not allow running this script directly; instead, call with input
    %from a script
    if nargin == 0; error('Do not run directly; call from a script instead.'); end

    %calculate bounding box based on all visual elements (labels included)
    %get normal vector (and catch error) in case of 2d mech
    %visualize boundary conditions
    %visualize loads and inputs
    
    figure;
    
    %legend axes
    subplot(1,2,1);
    hold on
    leg1 = plot(0,0); text(1,0,'node');
    leg2 = plot(0,-0.2); text(1,-0.2,'node with mass and/or inertia');
    leg3 = plot(0,-0.4); text(1,-0.4,'fixed node (all directions)');
    leg4 = plot(0,-0.6); text(1,-0.6,'fixed node (one or two dir.)');
    leg5 = text(0,0.2,'#'); text(1,0.2,'node number');
    leg6 = text(0,0.4,'#'); text(1,0.4,'element number');

    set(gca,'DataAspectRatio',[5 1 1])
    set(gca,'Position',[0.1 0.1 0.3 0.8])
    set(gca,'Visible','off')
    set(gca,'XLim',[0 2])
    set(gca,'YLim',[-1 1])
    
    %mechanism axes
    ah = subplot(1,2,2);
    set(ah,'Projection','perspective')
    hold on
    
    %handy vars
    nno = size(no,1);
    nel = size(el,1);
    
    %check input
        % no input and load on same node-direction
        
        % elements are connected to defined nodes
        if any(el(:)<=0), error('Element seems connected to node number <=0.'); end
        if max(el(:))>nno, error('Element seems connected to node that does not exist.'); end
        if any((el(:,1)-el(:,2))==0), error('Element seems connected to the same node.'); end
        
    %plot elements
    eh = [];
    for i=1:nel
        eh(i) = plot3(...
                    [no(el(i,1),1) no(el(i,2),1)], ...
                    [no(el(i,1),2) no(el(i,2),2)], ...
                    [no(el(i,1),3) no(el(i,2),3)]);
    end
    
    %plot nodes
    nh = [];
    for i=1:nno
        nh(i) = plot3(no(i,1),no(i,2),no(i,3));
    end
    
    %get largest and characteristisch distance of system
    maxdistiter = [];
    maxdistiteri = [];
    for i=1:nno
       relvec = no-repmat(no(i,:),size(no,1),1);
       dist = sqrt(sum(relvec.*relvec,2));
       [maxdistiter(i), maxdistiteri(i)] = max(dist);
    end
    [maxdist, maxdisti] = max(maxdistiter);
    nmax2 = maxdistiteri(maxdisti);
    nmax1 = maxdisti;
    clen = maxdist/20; %for distance between node and its label
    arrowlength = maxdist/6; %for length of arrows
    
    %get average plane through nodes
    planecoef = [no(:,1) no(:,2) ones(nno,1)]\no(:,3);
    normalvec = planecoef;
    normalvec(3) = -1;
    normalvec = normVec(normalvec);
    
    %plot node numbers
    nnh = [];
    for i=1:nno
        
        %get unit vectors pointing out of node
        outvectors = [];
        [ni,nj]=find(el==i); %indices of node in el matr
        node_mult = length(ni); %nr of elements attached to node
        
        if node_mult == 0
            npos = no(i,:) + clen*[1 1 1];
        else
            for j=1:node_mult
                if nj(j)==1, k=2; end
                if nj(j)==2, k=1; end
                connecting_node = el(ni(j),k);
                connecting_vec = no(connecting_node,:) - no(i,:);
                outvectors(j,:) = normVec(connecting_vec);
            end
        end
        
        if node_mult == 1
            dir = cross(outvectors(1,:),normalvec);
            npos = no(i,:) + clen*normVec(dir);
        end
        if node_mult == 2 
        
            ang = acosd(dot(outvectors(1,:),outvectors(2,:)));
            if ang < 2
                % parallel
                dir = cross(outvectors(1,:),normalvec);
                npos = no(i,:) + clen*normVec(dir);
            elseif ang > 178
                % anti-parallel
                dir = cross(outvectors(1,:),normalvec);
                npos = no(i,:) + clen*normVec(dir);
            else
                %  span plane, traverse midangle
                bisec = normVec(outvectors(1,:)+outvectors(2,:));
                npos = -clen*bisec + no(i,:);
            end
            
        end
        
        if node_mult == 3
            % bisector of two vecs, then another bisector with remain. 
            bisec1 = normVec(outvectors(1,:)+outvectors(2,:));
            bisec2 = normVec(bisec1+outvectors(3,:));
            npos = -clen*bisec2 + no(i,:);
        end
        
        if node_mult > 3
            %  give up on heuristics, just choose something
            npos = no(i,:) + clen*[1 1 1];
        end
        
        nnh(i) = text(npos(1),npos(2),npos(3),num2str(i));
    end
    
    %plot element numbers
    enh = [];
    for i=1:nel
        enh(i) = text(...
                    [no(el(i,1),1)+no(el(i,2),1)]/2, ...
                    [no(el(i,1),2)+no(el(i,2),2)]/2, ...
                    [no(el(i,1),3)+no(el(i,2),3)]/2, ...
                    num2str(i));
    end
    
    %visual properties
    set([nh leg1],'Marker','.','MarkerSize',16,'Color','k')
    set([leg2],'Marker','.','MarkerSize',16,'Color','r')
    set([leg3],'Marker','.','MarkerSize',16,'Color','b')
    set([leg4],'Marker','.','MarkerSize',16,'Color','g')
    set(eh,'Color',0.5*[1 1 1],'LineWidth',2.5)
    set([nnh leg5],'BackgroundColor','w','Color','b')
    set([enh leg6],'BackgroundColor','w','EdgeColor','k')
%     set(gca,'color',get(gcf,'color'))
    grid on
    
    %axes
    xlabel('x');
    ylabel('y');
    zlabel('z');
    axis(getAxesLim(no,arrowlength))
    set(gca,'DataAspectRatio',[1 1 1])
    [az,el] = view(normalvec);
    if el<0
        view(az,20)
    end
    
    %plot force
    for i=1:size(nopr,2)
        if(isfield(nopr(i),'force') && ~isempty(nopr(i).force))
            arrow3(no(i,:)-normVec(nopr(i).force)*arrowlength, ...
                    no(i,:)-normVec(nopr(i).force)*clen/2,[],1.5,3)
        end
    end
    
end

function res = normVec(vec)
    res = vec/norm(vec);
end

function lim = getAxesLim(no,arrowlength)
    offset = 0.1;
    xmax = max(no(:,1));
    xmin = min(no(:,1));
    dx = xmax - xmin;
    
    ymax = max(no(:,2));
    ymin = min(no(:,2));
    dy = ymax - ymin;
    
    zmax = max(no(:,3));
    zmin = min(no(:,3));
    dz = zmax - zmin;
    
    d = max([dx dy dz]);
    
    corrx = max([arrowlength offset*d]);
    corry = max([arrowlength offset*d]);
    corrz = max([arrowlength offset*d]);
    lim = [xmin xmax ymin ymax zmin zmax] + [-corrx corrx -corry corry -corrz corrz];
end