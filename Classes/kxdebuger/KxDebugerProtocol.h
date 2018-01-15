/*
*   KxDebuger–≠“È√¸¡Ó
*
*   2015-11-19 by ±¶“Ø
*/
#ifndef __KX_DEBUGER_PROTOCOL_H__
#define __KX_DEBUGER_PROTOCOL_H__

namespace kxdebuger {

struct Head {
    int length;
    int serviceId;
    int actionId;
};

enum ServicesId
{
    ServiceBase,
    ServiceNode
};

enum ActionId
{
    ActionBase = 0,
    ActionPauseOrResume,
    ActionStep,
    ActionLogicStep,

    ActionNode = 100,
    ActionQueryNodeTree,
    ActionQueryNodeInfo,
    ActionModifyNodeInfo,
    ActionActiveNode,
    ActionRemoveNode,
};

}

#endif // !__KX_DEBUGER_PROTOCOL_H__
