




function[I1_r,I2_r,I1_rs,I2_rs,overlap,mosaic,t_form,pos]=...
    Transformation(I1_o,I2_o,cor1,cor2,...
    trans_form,out_form,chg_scale,show_flag,overlap_flag,mosaic_flag)


    if contains(trans_form,'polynomial')
        trans_form=strsplit(trans_form,'-');
        if numel(trans_form)>1
            poly_order=str2double(trans_form{end});
        else
            poly_order=2;
        end
        trans_form='polynomial';
        t_form=fitgeotrans(cor2(:,1:2),cor1(:,1:2),trans_form,poly_order);
        trans={t_form.Degree,t_form.A,t_form.B};
    else
        t_form=fitgeotrans(cor2(:,1:2),cor1(:,1:2),trans_form);
        trans=t_form.T;
    end


    [M1,N1,B1]=size(I1_o);
    [M2,N2,B2]=size(I2_o);
    Cs=[[1,1];[N2,1];[1,M2];[N2,M2]];
    [Cs,~]=XY_Transform(Cs,{trans,trans_form},1);
    C1=Cs(1,:);C2=Cs(2,:);C3=Cs(3,:);C4=Cs(4,:);

    switch lower(out_form)
    case 'reference'
        dX=0;dY=0;sX=N1;sY=M1;
        pos=[1,1,N1,M1];
    case 'union'
        dX=min([C1(1),C2(1),C3(1),C4(1)]);dX=(dX<=1)*(1-dX);
        dY=min([C1(2),C2(2),C3(2),C4(2)]);dY=(dY<=1)*(1-dY);
        sX=max([C1(1),C2(1),C3(1),C4(1)]);sX=ceil(max(N1,sX)+dX);
        sY=max([C1(2),C2(2),C3(2),C4(2)]);sY=ceil(max(M1,sY)+dY);
        pos=[1-dX,1-dY,sX-dX,sY-dY];
    case 'inter'
        X_left=min([C1(1),C2(1),C3(1),C4(1)]);dX=(X_left>1)*(1-X_left);X_left=max(X_left,1);
        Y_up=min([C1(2),C2(2),C3(2),C4(2)]);dY=(Y_up>1)*(1-Y_up);Y_up=max(Y_up,1);
        X_right=max([C1(1),C2(1),C3(1),C4(1)]);X_right=min(N1,X_right);sX=ceil(X_right-X_left);
        Y_down=max([C1(2),C2(2),C3(2),C4(2)]);Y_down=min(M1,Y_down);sY=ceil(Y_down-Y_up);
        pos=[X_left,Y_up,X_right,Y_down];
    case 'geo'
        dX=0;dY=0;sX=0;sY=0;
        X_left=min([C1(1),C2(1),C3(1),C4(1)]);
        Y_up=min([C1(2),C2(2),C3(2),C4(2)]);
        X_right=max([C1(1),C2(1),C3(1),C4(1)]);
        Y_down=max([C1(2),C2(2),C3(2),C4(2)]);
        pos=[X_left,Y_up,X_right,Y_down];
        if show_flag
            [~,~,I1_rs,I2_rs,overlap,mosaic,~]=Transformation(I1_o,I2_o,cor1,cor2,...
            trans_form,'inter',0,1,overlap_flag,mosaic_flag);
        end
    end


    if strcmpi(out_form,'union')||strcmpi(out_form,'inter')
        trans_1=[1,0,0;0,1,0;dX,dY,1];
        t_form=projective2d(trans_1);
        I1_r=imwarp(I1_o,t_form,'OutputView',imref2d([sY,sX]));
    else
        I1_r=[];
    end
    cor1=[cor1(:,1)+dX,cor1(:,2)+dY];

    if~chg_scale
        t_form=fitgeotrans(cor1(:,1:2),cor2(:,1:2),'similarity');
        trans=t_form.T;
        Rx=sqrt(trans(1,1)^2+trans(1,2)^2);
        Ry=sqrt(trans(2,1)^2+trans(2,2)^2);
        sX=round(sX*Rx);sY=round(sY*Ry);
        cor1=[cor1(:,1)*Rx,cor1(:,2)*Ry];
    end

    t_form=fitgeotrans(cor2(:,1:2),cor1(:,1:2),trans_form);
    if~strcmpi(out_form,'geo')
        I2_r=imwarp(I2_o,t_form,'OutputView',imref2d([sY,sX]));
    else
        I2_r=imwarp(I2_o,t_form);
    end

    if~show_flag
        I1_rs=[];I2_rs=[];overlap=[];mosaic=[];return
    elseif strcmpi(out_form,'geo')
        return
    end


    ex_size=4096;
    if strcmpi(out_form,'reference')||strcmpi(out_form,'geo')
        [I1_rs,~]=dealWithExtremes(I1_o,1,ex_size,1);
    else
        [I1_rs,~]=dealWithExtremes(I1_r,1,ex_size,1);
    end
    [I2_rs,~]=dealWithExtremes(I2_r,1,ex_size,1);


    if strcmpi(out_form,'inter')
        common=(sum(I1_rs,3)~=0)&...
        (sum(imresize(I2_rs,[size(I1_rs,1),size(I1_rs,2)]),3)~=0);
        for k=1:B1
            band_t=I1_rs(:,:,k);
            band_t(common==0)=0;
            I1_rs(:,:,k)=band_t;
        end
        common=imresize(common,[size(I2_rs,1),size(I2_rs,2)]);
        for k=1:B2
            band_t=I2_rs(:,:,k);
            band_t(common==0)=0;
            I2_rs(:,:,k)=band_t;
        end
    end
    % clearband_tcommon


    if B1~=1&&B1~=3
        I1_rs=sum(double(I1_rs),3);
    else
        I1_rs=double(I1_rs);
    end
    I1_rs=visualizeImage(I1_rs);

    if B2~=1&&B2~=3
        I2_rs=sum(double(I2_rs),3);
    else
        I2_rs=double(I2_rs);
    end
    I2_rs=visualizeImage(I2_rs);


    if overlap_flag||mosaic_flag
        if B1==1&&B2==3
            I1_rs=repmat(I1_rs,[1,1,3]);

        elseif B1==3&&B2==1
            I2_rs=repmat(I2_rs,[1,1,3]);

        end
        if~chg_scale
            I2_rs=imresize(I2_rs,[size(I1_rs,1),size(I1_rs,2)]);
        end
    end

    mask_1=sum(I1_rs,3);mask_1=ceil(mask_1/max(mask_1(:)));
    mask_2=sum(I2_rs,3);mask_2=ceil(mask_2/max(mask_2(:)));
    mask_12=floor((mask_1+mask_2)/2);
    mask_1=mask_1-mask_12;mask_2=mask_2-mask_12;
    if(B1==3||B2==3)
        mask_1=repmat(mask_1,[1,1,3]);
        mask_2=repmat(mask_2,[1,1,3]);
        mask_12=repmat(mask_12,[1,1,3]);
    end


    if overlap_flag

        overlap=I1_rs.*mask_1+I2_rs.*mask_2+...
        (I1_rs/2+I2_rs/2).*mask_12;
    else
        overlap=[];
    end


    if mosaic_flag
        grid_num=4;
        grid_size=floor(min(size(I1_rs,1),size(I1_rs,2))/grid_num);
        [~,~,mosaic]=mosaicMapping(I1_rs,I2_rs,grid_size);
        mosaic=I1_rs.*mask_1+I2_rs.*mask_2+...
        mosaic.*mask_12;
    else
        mosaic=[];
    end



    function[points,trans_t]=XY_Transform(points,transs,flag)

        trans_t=transs;
        trans_t(1:end,1)={[1,0,0;0,1,0;0,0,1]};
        trans_t(1:end,2)={'affine'};

        if isempty(points)
            return
        end
        points=[points(:,1:2),ones(size(points,1),1)];

        k=1;
        for i=1:size(transs,1)
            tform=transs{i,2};
            if strcmpi(tform,'nonreflectivesimilarity')||strcmpi(tform,'similarity')||strcmpi(tform,'affine')
                trans_t{k,1}=trans_t{k,1}*transs{i,1};
            elseif strcmpi(tform,'projective')
                if i~=1
                    k=k+1;
                end
                trans_t(k,:)=transs(i,:);
                if i~=size(transs,1)
                    k=k+1;
                end
            end
        end
        trans_t=trans_t(1:k,:);

        if flag==1
            for i=1:size(trans_t,1)
                tform=trans_t{i,2};
                if strcmpi(tform,'affine')
                    points=points*trans_t{i,1};
                elseif strcmpi(tform,'projective')
                    M=trans_t{i,1};
                    W=points(:,1)*M(1,3)+points(:,2)*M(2,3)+M(3,3);
                    points(:,1:2)=...
                    [(points(:,1)*M(1,1)+points(:,2)*M(2,1)+M(3,1))./W,...
                    (points(:,1)*M(1,2)+points(:,2)*M(2,2)+M(3,2))./W];
                end
            end

        elseif flag==-1
            for i=size(trans_t,1):-1:1
                tform=trans_t(i,2);
                if strcmpi(tform,'affine')
                    points=points/trans_t{i,1};
                elseif strcmpi(tform,'projective')
                    M=inv(trans_t{i,1});
                    W=points(:,1)*M(1,3)+points(:,2)*M(2,3)+M(3,3);
                    points(:,1:2)=...
                    [(points(:,1)*M(1,1)+points(:,2)*M(2,1)+M(3,1))./W,...
                    (points(:,1)*M(1,2)+points(:,2)*M(2,2)+M(3,2))./W];
                end
            end
        end