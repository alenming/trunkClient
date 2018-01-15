#include "CsbTool.h"

#if (COCOS2D_VERSION >= 0x00031000)
#include "cocostudio/CCComExtensionData.h"
#else
#include "cocostudio/CCObjectExtensionData.h"
#endif

#include "cocostudio/CocoStudio.h"
#include "ui/CocosGUI.h"

USING_NS_CC;
using namespace cocostudio;
using namespace ui;
using namespace timeline;

enum NodeType
{
    WidgetNode,
    CsbNode,
    SpriteNode
};

void copyExtInfo(Node* src, Node* dst)
{
    if (src == nullptr || dst == nullptr)
    {
        return;
    }

#if (COCOS2D_VERSION >= 0x00031000)
    auto com = dynamic_cast<ComExtensionData*>(
        src->getComponent(ComExtensionData::COMPONENT_NAME));

    if (com)
    {
        ComExtensionData* extensionData = ComExtensionData::create();
        extensionData->setCustomProperty(com->getCustomProperty());
        extensionData->setActionTag(com->getActionTag());
        if (dst->getComponent(ComExtensionData::COMPONENT_NAME))
        {
            dst->removeComponent(ComExtensionData::COMPONENT_NAME);
        }
        dst->addComponent(extensionData);
    }
#else
    auto obj = src->getUserObject();
    if (obj != nullptr)
    {
        ObjectExtensionData* objExtData = dynamic_cast<ObjectExtensionData*>(obj);
        if (objExtData != nullptr)
        {
            auto newObjExtData = ObjectExtensionData::create();
            newObjExtData->setActionTag(objExtData->getActionTag());
            newObjExtData->setCustomProperty(objExtData->getCustomProperty());
            dst->setUserObject(newObjExtData);
        }
    }
#endif

    // 拷贝Action
    int tag = src->getTag();
    if (tag != Action::INVALID_TAG)
    {
        auto action = dynamic_cast<ActionTimeline*>(src->getActionByTag(src->getTag()));
        if (action)
        {
            dst->runAction(action->clone());
        }
    }
}

void copyLayoutComponent(Node* src, Node* dst)
{
    if (src == nullptr || dst == nullptr)
    {
        return;
    }

    // 检查是否有布局组件
    LayoutComponent * layout = dynamic_cast<LayoutComponent*>(src->getComponent(__LAYOUT_COMPONENT_NAME));
    if (layout != nullptr)
    {
        auto layoutComponent = ui::LayoutComponent::bindLayoutComponent(dst);
        layoutComponent->setPositionPercentXEnabled(layout->isPositionPercentXEnabled());
        layoutComponent->setPositionPercentYEnabled(layout->isPositionPercentYEnabled());
        layoutComponent->setPositionPercentX(layout->getPositionPercentX());
        layoutComponent->setPositionPercentY(layout->getPositionPercentY());
        layoutComponent->setPercentWidthEnabled(layout->isPercentWidthEnabled());
        layoutComponent->setPercentHeightEnabled(layout->isPercentHeightEnabled());
        layoutComponent->setPercentWidth(layout->getPercentWidth());
        layoutComponent->setPercentHeight(layout->getPercentHeight());
        layoutComponent->setStretchWidthEnabled(layout->isStretchWidthEnabled());
        layoutComponent->setStretchHeightEnabled(layout->isStretchHeightEnabled());
        layoutComponent->setHorizontalEdge(layout->getHorizontalEdge());
        layoutComponent->setVerticalEdge(layout->getVerticalEdge());
        layoutComponent->setTopMargin(layout->getTopMargin());
        layoutComponent->setBottomMargin(layout->getBottomMargin());
        layoutComponent->setLeftMargin(layout->getLeftMargin());
        layoutComponent->setRightMargin(layout->getRightMargin());
    }
}

NodeType getNodeType(Node* node)
{
    if (dynamic_cast<Widget*>(node) != nullptr)
    {
        return WidgetNode;
    }
    else if (dynamic_cast<Sprite*>(node) != nullptr)
    {
        return SpriteNode;
    }
    else
    {
        return CsbNode;
    }
}

Sprite* cloneSprite(Sprite* sp);

void cloneChildren(Node* src, Node* dst)
{
    if (src == nullptr || dst == nullptr)
    {
        return;
    }

    for (auto& n : src->getChildren())
    {
        NodeType ntype = getNodeType(n);
        Node* child = nullptr;
        switch (ntype)
        {
        case WidgetNode:
            // 如果父节点也是Widget，则该节点已经被拷贝了
            if (dynamic_cast<Widget*>(src) == nullptr)
            {
                child = dynamic_cast<Widget*>(n)->clone();
                dst->addChild(child);
            }
            else
            {
                // 如果节点已经存在，找到它
                for (auto dchild : dst->getChildren())
                {
                    if (dchild->getTag() == n->getTag()
                        && dchild->getName() == n->getName())
                    {
                        child = dchild;
                        break;
                    }
                }
            }
            if (dynamic_cast<Text*>(n) != nullptr)
            {
                auto srcText = dynamic_cast<Text*>(n);
                auto dstText = dynamic_cast<Text*>(child);
                if (srcText && dstText)
                {
                    dstText->setTextColor(srcText->getTextColor());
                }
            }
            child->setCascadeColorEnabled(n->isCascadeColorEnabled());
            child->setCascadeOpacityEnabled(n->isCascadeOpacityEnabled());
            copyLayoutComponent(n, child);
            cloneChildren(n, child);
            copyExtInfo(n, child);
            break;
        case CsbNode:
            child = CsbTool::cloneCsbNode(n);
            dst->addChild(child);
            break;
        case SpriteNode:
            child = cloneSprite(dynamic_cast<Sprite*>(n));
            dst->addChild(child);
            break;
        default:
            break;
        }
    }
}

Sprite* cloneSprite(Sprite* sp)
{
    Sprite* newSprite = Sprite::create();
    newSprite->setName(sp->getName());
    newSprite->setTag(sp->getTag());
    newSprite->setPosition(sp->getPosition());
    newSprite->setVisible(sp->isVisible());
    newSprite->setAnchorPoint(sp->getAnchorPoint());
    newSprite->setLocalZOrder(sp->getLocalZOrder());
    newSprite->setRotationSkewX(sp->getRotationSkewX());
    newSprite->setRotationSkewY(sp->getRotationSkewY());
    newSprite->setTextureRect(sp->getTextureRect());
    newSprite->setTexture(sp->getTexture());
    newSprite->setSpriteFrame(sp->getSpriteFrame());
    newSprite->setBlendFunc(sp->getBlendFunc());
    newSprite->setScaleX(sp->getScaleX());
    newSprite->setScaleY(sp->getScaleY());
    newSprite->setFlippedX(sp->isFlippedX());
    newSprite->setFlippedY(sp->isFlippedY());
    newSprite->setContentSize(sp->getContentSize());
    newSprite->setOpacity(sp->getOpacity());
    newSprite->setColor(sp->getColor());
    newSprite->setCascadeColorEnabled(true);
    newSprite->setCascadeOpacityEnabled(true);
    copyLayoutComponent(sp, newSprite);
    cloneChildren(sp, newSprite);
    copyExtInfo(sp, newSprite);
    return newSprite;
}

// 如果传入的是一个Csb Node
Node* CsbTool::cloneCsbNode(Node* node)
{
    Node* newNode = Node::create();
    newNode->setName(node->getName());
    newNode->setTag(node->getTag());
    newNode->setPosition(node->getPosition());
    newNode->setScaleX(node->getScaleX());
    newNode->setScaleY(node->getScaleY());
    newNode->setAnchorPoint(node->getAnchorPoint());
    newNode->setLocalZOrder(node->getLocalZOrder());
    newNode->setVisible(node->isVisible());
    newNode->setOpacity(node->getOpacity());
    newNode->setColor(node->getColor());
    newNode->setCascadeColorEnabled(true);
    newNode->setCascadeOpacityEnabled(true);
    newNode->setContentSize(node->getContentSize());
    copyLayoutComponent(node, newNode);
    cloneChildren(node, newNode);
    copyExtInfo(node, newNode);
    return newNode;
}