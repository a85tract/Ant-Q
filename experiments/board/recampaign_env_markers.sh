# Device / marker programs on top of the campaign environment: source AFTER recampaign_env.sh.
# Used by the handover measurement (recampaign_accept.sh step 3, bench marker programs) and by the device session. ANTQ_QCHIP / ANTQ_QCHIP_PATCH are a
# device's chip configuration and calibrated pulse export: a device session needs both; unset, the runner uses the bench
# configuration benchmark/qubitcfg_14q_gate.json. This repository does not ship a device chip configuration.
_here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$_here/recampaign_env.sh"
export ANTQ_BENCH_DIR=${ANTQ_BENCH_DIR:-$_here/../../benchmark}
export ANTQ_PHYS_MODULE=${ANTQ_PHYS_MODULE:-$_here/../device_x6y3/aqt_programs.py}
[ -n "${ANTQ_QCHIP:-}" ] && export ANTQ_QCHIP
[ -n "${ANTQ_QCHIP_PATCH:-}" ] && export ANTQ_QCHIP_PATCH
export AQT_QUBIT=${AQT_QUBIT:-Q5}
