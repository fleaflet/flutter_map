import React from 'react';
import clsx from 'clsx';
import styles from './HomepageFeatures.module.css';

const FeatureList = [
  {
    title: 'Easy & Powerful',
    Svg: require('../../static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        flutter_map was designed to be easily setup, but with powerful configuration and functionality. From a simple Open Street Map showing your local area to a multi-appearance fitness app, flutter_map has what you need.
      </>
    ),
  },
  {
    title: 'Focus on What Matters',
    Svg: require('../../static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        This documentation guides you through what matters most to most users, but it barely scratches the surface of the whole API. That's why you can also check-out the <a href='https://pub.dev/documentation/flutter_map/latest/flutter_map/flutter_map-library.html'>Full API Reference</a>, that also appears in your favourite IDE, helping you write code faster and more efficiently.
      </>
    ),
  },
  {
    title: 'Extended by the Community',
    Svg: require('../../static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        The flutter_map community is full of people who want to help you fix a problem, people that want to see new functionality, and people who create new functionality. Over 200 PRs have been merged to date, and there are more than 10 independently maintained plugins that help you get prebuilt solutions quicker, a number which is quickly increasing.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} alt={title} />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
