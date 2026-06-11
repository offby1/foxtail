#!/bin/bash

echo "🔍 Checking Foxtail container status..."
echo ""

echo "📋 Supervisor processes:"
docker exec foxtail supervisorctl status
echo ""

echo "📋 Running processes:"
docker exec foxtail ps aux | grep -E "(Xvfb|x11vnc|firefox|novnc)" | grep -v grep
echo ""

echo "📋 Display environment:"
docker exec foxtail bash -c 'echo "DISPLAY=$DISPLAY"'
echo ""

echo "📋 X server test (should show screen info):"
docker exec foxtail bash -c 'DISPLAY=:99 xdpyinfo 2>&1 | head -20' || echo "X server not responding"
echo ""

echo "📋 Recent Firefox logs:"
docker logs foxtail 2>&1 | grep -i firefox | tail -20
echo ""

echo "📋 Test pattern (try to open xterm):"
docker exec foxtail bash -c 'DISPLAY=:99 xterm &' 2>&1 || echo "Could not open test window"

echo ""
echo "💡 If Xvfb is running but screen is black:"
echo "   - Firefox might have failed to start"
echo "   - Check: docker exec foxtail supervisorctl tail firefox"
