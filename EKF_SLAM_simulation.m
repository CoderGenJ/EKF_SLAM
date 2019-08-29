% EKF_SLAM �����ļ�
% 
% ������ 2019
close all
clear all

% ����ģ�Ͳ���
simulation_config

% ��������
load(MAP_DATA)
    
% ���عؼ���
key_points = data_original.key_points;
% ����·��
landmarks = data_original.landmarks;
% ����״̬
states = data_original.states;
% ����·���ؼ���
wp = data_original.key_points;

% ��ȡ���г���
length = size(states,2);

if ADD_COLOR_NOISE == 1
    noise_V = gen_color_noise(length,Q(1,1),c);
    noise_G = gen_color_noise(length,Q(2,2),c);
%     noise_r = gen_color_noise(length,R(1,1));
%     noise_t = gen_color_noise(length,R(2,2));
    for i = 1:1:length
        states(i).Vn = states(i).V + noise_V(i);
        states(i).Gn = states(i).G + noise_G(i);
%         states(i).Vn = states(i).V + noise_r(i);
%         states(i).Vn = states(i).V + noise_t(i);
    end
end

ture_trajectory = zeros(3,length);
model_pre_trajectory = zeros(3,length);
EKF_pre_trajectory = zeros(3,length);

x= states(1).xtrue; % ״̬����
P= zeros(3); % Э�������
QE= 2*Q; % ���Ʊ�����Э�������
RE= 2*R; % ������Э�������
ftag= 1:size(landmarks,2);
da_table= zeros(1,size(landmarks,2));
dt = DT_CONTROLS;

if ASYNCHRONOUS == 1
    dt = DT_OBSERVE;
end

x_model_pre = x;

if SLAM_SAVE_GIF == 1

    if exist('ekf_slam.avi','file') == 2
        delete('ekf_slam.avi');
    end
    
    if exist('ekf_slam.gif','file') == 2
        delete('ekf_slam.gif');
    end
    
    %����avi�ļ�����
    aviobj = VideoWriter('ekf_slam.avi','Uncompressed AVI');
    open(aviobj)
end

% ѭ���㷨����
fig = figure;
hold on;
for k = 1:1:length
    
    % ��ȡ������
    Vn = states(k).Vn;
    Gn = states(k).Gn;
     
    if ASYNCHRONOUS == 0
        % EKF����״̬Ԥ��ֵ��Э����
        [x,P] = EKF_predict (x,P, Vn,Gn,QE, WHEELBASE,dt);
        % ��ȡ��ͨ��ģ��Ԥ���λ��
        x_model_pre = vehicle_model(x_model_pre, Vn,Gn, WHEELBASE,dt);
    end
    
    if states(k).observation_update == 1
        
        if ASYNCHRONOUS == 1
            % EKF����״̬Ԥ��ֵ��Э����
            [x,P] = EKF_predict (x,P, Vn,Gn,QE, WHEELBASE,dt);
            % ��ȡ��ͨ��ģ��Ԥ���λ��
            x_model_pre = vehicle_model(x_model_pre, Vn,Gn, WHEELBASE,dt);
        end
        % ��ȡ�۲�ֵ
        z = states(k).zn;
        ftag_visible = states(k).ftag_visible;
        
        if REDUCE_OB_FEATURES == 1
            % �����۲⵽��landmark��Ŀ
            if size(z,2) > 1
                z = z(:,1);
                ftag_visible = ftag_visible(1);
            end
        end
        
        % ���ݹ���
        if SWITCH_ASSOCIATION_KNOWN == 1
            [zf,idf,zn, da_table]= data_associate_known(x,z,ftag_visible, da_table);
        else
            [zf,idf, zn]= data_associate(x,P,z,RE, GATE_REJECT, GATE_AUGMENT); 
        end
        
        % ����״̬����
        if SWITCH_USE_IEKF == 1
            [x,P]= update_iekf(x,P,zf,RE,idf, 5);
        else
            [x,P]= EKF_update(x,P,zf,RE,idf, 1); 
        end
        
        % ����µ�landmark��״̬������
        [x,P]= augment(x,P, zn,RE); 
    end
    
    xtrue = states(k).xtrue;
    iwp = states(k).next_keypoint;
    
    % ���ͼ��
    cla;
    axis equal
   
    ture_trajectory(:,k) = xtrue(1:3);
    model_pre_trajectory(:,k) = x_model_pre(1:3);
    EKF_pre_trajectory(:,k) = x(1:3);
    
    % ������ʷ�켣
     plot( ture_trajectory(1, 1:k), ture_trajectory(2, 1:k), 'k--','linewidth',3);
    
    % ������ʷEKFԤ��켣
    plot( EKF_pre_trajectory(1, 1:k), EKF_pre_trajectory(2, 1:k), 'r','linewidth',3 );
    
    % ������ʷmodelԤ��켣
    plot( model_pre_trajectory(1, 1:k), model_pre_trajectory(2, 1:k), 'b-.','linewidth',3);
    
     % ����landmarks
    scatter( landmarks(1, :), landmarks(2, :), 'b*' );
    
    % ����·���ؼ���
    plot( wp(1,:), wp(2, :), 'r.','markersize',26 );
    
    % ����Ŀ����λ��
    if iwp~=0
       plot(wp(1,iwp),wp(2,iwp),'bo','markersize',13,'linewidth',1);
    end
    
    % ��������λ��
    draw_car(xtrue,5,'k');
    
    % EKFԤ��λ��
    draw_car(x,5,'r');
    
    % ģ��Ԥ��λ��
    draw_car(x_model_pre,5,'g');

    % ���������״�۲ⷶΧ
    draw_circle(xtrue(1), xtrue(2),MAX_RANGE);

    if ~isempty(z)
        % ���������״�۲���
        plines = make_laser_lines(z,xtrue);
        plot(plines(1,:),plines(2,:));
        
%         pellipses = make_covariance_ellipses(x,P);
%         plot(pellipses(1,:),pellipses(2,:));
    end
    
%     legend([truep ekfp,modelp],'true','ekf','model');

    pause(0.00000001)
    
    if SLAM_SAVE_GIF == 1
        %��ȡ��ǰ����
        F = getframe(fig);
        %����avi������
        writeVideo(aviobj,F);
        
        %ת��gifͼƬ,ֻ����256ɫ
        im = frame2im(F);
        [I,map] = rgb2ind(im,256);
        %д�� GIF89a ��ʽ�ļ�   
        if k == 1
            imwrite(I,map,'ekf_slam.gif','GIF', 'Loopcount',inf,'DelayTime',0.1);
        else
            imwrite(I,map,'ekf_slam.gif','GIF','WriteMode','append','DelayTime',0.1);
        end
    end 
    
    sim_result.states(k).xtrue = xtrue;
    sim_result.states(k).x_model_pre = x_model_pre;
    sim_result.states(k).x = x;
    sim_result.states(k).P = P;
    
end

sim_result.landmarks = landmarks;
sim_result.ture_trajectory = ture_trajectory;
sim_result.EKF_pre_trajectory = EKF_pre_trajectory;
sim_result.model_pre_trajectory = model_pre_trajectory;
sim_result.wp = wp;

save sim_result sim_result;



