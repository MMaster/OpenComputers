local component = require("component");
local computer = require("computer");
local event = require("event");
local oop = require("oop");

local frame_base = require("libGUI/frame");

local libGUI = {
	mGPU = nil,
	mRootFrame = nil,
	mRestoreInfo = {
		backgroundColor = nil,
		foregroundColor = nil,
		resolutionX = nil,
		resolutionY = nil
	},
	mTemplates = {},
	mOptimalResolutionFactor = 1,
	mAspectLast = 1,
	mRedrawTimerId = nil;
};

function libGUI.init()
	libGUI.mRootFrame = frame_base();
	libGUI.useSuitableGPU();

	event.listen("touch", libGUI.onEventTouch);
	event.listen("screen_resized", libGUI.onEventResize);
end

function libGUI.deinit()
	libGUI.reset();

	event.ignore("touch", libGUI.onEventTouch);
	event.ignore("screen_resized", libGUI.onEventResize);
end

function libGUI.restore()
	libGUI.mGPU.setBackground(libGUI.mRestoreInfo.backgroundColor);
	libGUI.mGPU.setForeground(libGUI.mRestoreInfo.foregroundColor);
	libGUI.mGPU.setResolution(libGUI.mRestoreInfo.resolutionX, libGUI.mRestoreInfo.resolutionY);
end

function libGUI.reset()
	if libGUI.mGPU ~= nil then
		libGUI.restore();
	end
	libGUI.mGPU = nil;
	libGUI.mRootFrame = nil;
	libGUI.setRedrawInterval(nil);
end

function libGUI.exit()
	libGUI.deinit();
	computer.pushSignal("libGUI_terminate");
end

function libGUI.useSuitableGPU()
	local gpus = component.list("gpu", true);
	local screens = component.list("screen", true);

	local selected_gpu = nil;
	local selected_depth = 0;
	local selected_screen = nil;


	for address, _ in pairs(gpus) do
		if address ~= component.gpu.address then
			local gpu = component.proxy(address);
			if gpu.getDepth() > selected_depth then
				selected_gpu = gpu;
				selected_depth = gpu.getDepth();
			end
		end
	end

	for address, _ in pairs(screens) do
		if component.gpu.getScreen() ~= address then
			selected_screen = address;
		end
	end

	if selected_gpu == nil or selected_screen == nil then
		libGUI.setGPU(component.gpu);
	else
		selected_gpu.bind(selected_screen);
		libGUI.setGPU(selected_gpu);
	end
end

function libGUI.setGPU(gpu)
	local width, height = gpu.getResolution();
	if libGUI.mGPU ~= nil then
		libGUI.restore();
	end

	libGUI.mGPU = gpu;

	libGUI.mRestoreInfo.backgroundColor = gpu.setBackground(0);
	libGUI.mRestoreInfo.foregroundColor = gpu.setForeground(0xF0F0F0);
	libGUI.mRestoreInfo.resolutionX		= width;
	libGUI.mRestoreInfo.resolutionY		= height;
	gpu.fill(1, 1, width, height, ' ');

	libGUI.mRootFrame:setGPU(libGUI.mGPU);
	libGUI.mRootFrame:setSize(width, height);
end

function libGUI.setGPUByAddress(gpu_address)
	local gpu = component.proxy(gpu_address);
	if not gpu then
		io.stderr:write("GPU with address \"" .. gpu_address .. "\" not found.");
		return false;
	end
	libGUI.setGPU(gpu);
	return true;
end

function libGUI.setRootFrame(rootFrame)
	libGUI.mRootFrame = rootFrame;

	if libGUI.mGPU ~= nil then
		local width, height = libGUI.mGPU.getResolution();

		libGUI.mRootFrame:setGPU(libGUI.mGPU);
		libGUI.mRootFrame:setSize(width, height);
	end
end

function libGUI.setResolution(width, height)
	if libGUI.mGPU ~= nil then
		return libGUI.mGPU.setResolution(width, height);
	end
	return nil, nil;
end

function libGUI.getResolution()
	if libGUI.mGPU ~= nil then
		return libGUI.mGPU.getResolution();
	end
	return nil, nil;
end

function libGUI.setOptimalResolution(factor)
	if libGUI.mGPU == nil then
		return nil, nil;
	elseif factor == nil or factor > 1 then
		factor = 1;
	end

	local x, y = component.invoke(libGUI.mGPU.getScreen(), "getAspectRatio");
	local wMax, hMax = libGUI.mGPU.maxResolution();
	local pixelAspect = (x*14 - 4) / (y*7 - 2);
	local w1 = wMax * factor;
	local h1 = w1 / pixelAspect;
	local h2 = hMax * factor;
	local w2 = h2 * pixelAspect;
	
	libGUI.mOptimalResolutionFactor = factor;
	if h1 <= hMax * factor then
		return libGUI.setResolution(w1, h1);
	else
		return libGUI.setResolution(w2, h2);
	end
end

function libGUI.getRootFrame()
	return libGUI.mRootFrame;
end

---

function libGUI.redraw()
	local x, y = component.invoke(libGUI.mGPU.getScreen(), "getAspectRatio");
	if libGUI.mAspectLast ~= x/y then
		libGUI.setOptimalResolution(libGUI.mOptimalResolutionFactor);
		libGUI.mAspectLast = x/y;
	end
	libGUI.mRootFrame:onDraw();
end

function libGUI.setRedrawInterval(number)
	if libGUI.mRedrawTimerId ~= nil then
		event.cancel(libGUI.mRedrawTimerId);
		libGUI.mRedrawTimerId = nil;
	end
	if number ~= nil then
		libGUI.mRedrawTimerId = event.timer(number, libGUI.redraw, math.huge);
	end
end

function libGUI.runOrFork()
	local fork = not (libGUI.mGPU == component.gpu);
	
	if not fork then
		while event.pull(math.huge, "libGUI_terminate") == nil do end;
	end
end

function libGUI.run()
	while event.pull(math.huge, "libGUI_terminate") == nil do end;
end

--- Factory

function libGUI.registerFrameType(name, template)
	libGUI.mTemplates[name] = template;
end

function libGUI.newFrame(name, ...)
	if libGUI.mTemplates[name] ~= nil then
		return libGUI.mTemplates[name](...);
	else
		libGUI.registerFrameType(name, require("libGUI/" .. name));
		return libGUI.newFrame(name, ...);
	end
end

---

function libGUI.onEventTouch(eventID, address, x, y, button, playerName)
	if libGUI.mGPU and libGUI.mGPU.getScreen() == address then
		libGUI.mRootFrame:onTouch(x, y, button, playerName);
	end
end

function libGUI.onEventResize(eventId, address, newWidth, newHeight)
	if libGUI.mGPU and libGUI.mGPU.getScreen() == address then
		libGUI.mRootFrame:setSize(newWidth, newHeight);
		libGUI.mRootFrame:onDraw();
	end
end

return libGUI; --oop.exportFunctions(libGUI);
