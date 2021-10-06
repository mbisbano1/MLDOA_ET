%clear
try
    load('fpath.mat','fpath')
    [filename,fpath]=uigetfile([fpath '/*.jsf'], 'Which file to process?'); %open file and assign handle
catch
    [filename,fpath]=uigetfile('*.jsf', 'Which file to process?'); %open file and assign handle
end
save('fpath.mat','fpath')
fp = fopen([fpath,filename],'r');

figureOffset = 0;

PoBathyCtr = 1 ;
StBathyCtr = 1 ;
PortRange = NaN(5000,5000) ;
PortAngle = NaN(5000,5000) ;
PortAmp = NaN(5000,5000) ;
PortMaxSound = -1 ;

StbdRange = NaN(5000,5000) ;
StbdAngle = NaN(5000,5000) ;
StbdAmp = NaN(5000,5000) ;
StbdMaxSound = -1 ;


while PoBathyCtr < 100
    [mH, data, header] = readJSFv3_small(fp,[1:100]) ; % read all types of data
    
    if mH.contentType < 1 % should check for cause of error to display information about break condition
        break
    end
    
    if mH.contentType == 42 % bathy data
        if header.channel == 0 % port
            PortRange(PoBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            PortAngle(PoBathyCtr,1:header.nsamps) = -data.Angle ;
            PortAmp(PoBathyCtr,1:header.nsamps) = data.Amp ;
            PortHeader(PoBathyCtr) = header ;
            if header.nsamps > PortMaxSound
                PortMaxSound = header.nsamps ;
            end
            PoBathyCtr = PoBathyCtr + 1 ;
            if ~mod(PoBathyCtr,100)
                fprintf('.')
            end
        elseif header.channel == 1 % Stbd
            StbdRange(StBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            StbdAngle(StBathyCtr,1:header.nsamps) =  data.Angle  ;
            StbdAmp(StBathyCtr,1:header.nsamps) = data.Amp ;
            StbdHeader(StBathyCtr) = header ;
            if header.nsamps > StbdMaxSound
                StbdMaxSound = header.nsamps ;
            end
            
            StBathyCtr = StBathyCtr + 1 ;
            
        end
    elseif mH.contentType == 1 % could be sidescan, need to check subsystem ID to locate stave data
        if mH.subsystem == 40 || mH.subsystem == 40 % stave data combining port and starboard
            stavePort = data.samples(1:10,:) ; % stave order: stave 1 closest to seabed stave 10 closest to surface
            staveStarboard = data.samples(11:20,:) ; % % stave order: stave 11 closest to seabed stave 20 closest to surface
            timestamp = header.timeStamp ;
            % apply your processing here
        end
    end
end
fprintf('\n')

BathyCtr = min(PoBathyCtr,StBathyCtr) - 1;

PortRange = PortRange(1:BathyCtr,1:PortMaxSound) ;
PortAngle = PortAngle(1:BathyCtr,1:PortMaxSound) ;
PortAmp = PortAmp(1:BathyCtr,1:PortMaxSound) ;

StbdRange =  StbdRange(1:BathyCtr,1: StbdMaxSound) ;
StbdAngle =  StbdAngle(1:BathyCtr,1: StbdMaxSound) ;
StbdAmp =  StbdAmp(1:BathyCtr,1: StbdMaxSound) ;

PortX = PortRange.*sin(PortAngle);
PortY = repmat((1:size(PortX,1))',1,size(PortX,2)) ;
StbdX = StbdRange.*sin(StbdAngle);
StbdY = repmat((1:size(StbdX,1))',1,size(StbdX,2)) ;

PortZ = -PortRange.*cos(PortAngle);
StbdZ = -StbdRange.*cos(StbdAngle);

figure(1+figureOffset)
clf
imagesc([fliplr(PortZ) zeros(BathyCtr,1) StbdZ])
title(filename,'interpreter','none')
axis xy
colormap(jet)

figure(2+figureOffset)
imagesc([fliplr(PortAmp) zeros(BathyCtr,5) StbdAmp])
title(filename,'interpreter','none')
axis xy
colormap(gray)




